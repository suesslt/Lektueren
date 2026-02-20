//
//  PDFTreeViewModel.swift
//  Lektüren
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI
import SwiftData
import CryptoKit
import PDFKit

/// Observable ViewModel, das Folder und PDFs direkt
/// aus dem SwiftData / CloudKit Store fetcht.
/// Der ModelContext wird bei der Initialisierung injiziert.
@Observable
@MainActor
class PDFTreeViewModel: TreeViewModel {
    typealias Folder = PDFFolder
    typealias Leaf = PDFItem

    private(set) var rootFolders: [PDFFolder] = []
    var selectedFolder: PDFFolder?
    var selectedDetailItem: PDFItem?

    /// Die aktuell anzuzeigenden Items: Alle Items bei virtuellem Folder, sonst die des selektierten Folders.
    var displayedItems: [PDFItem] {
        guard let folder = selectedFolder else {
            print("📋 [Display] Kein Ordner ausgewählt")
            return []
        }
        
        if folder.isVirtual {
            var descriptor = FetchDescriptor<PDFItem>(sortBy: [SortDescriptor(\.title)])
            let items = (try? modelContext.fetch(descriptor)) ?? []
            print("📋 [Display] Virtueller Ordner 'Alle Lektüren': \(items.count) Items")
            return items
        }
        
        let items = folder.items ?? []
        print("📋 [Display] Ordner '\(folder.name ?? "Unbenannt")': \(items.count) Items")
        return items
    }

    /// Gesamtanzahl aller Items über alle Folders hinweg.
    var totalItemCount: Int {
        let descriptor = FetchDescriptor<PDFItem>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private let modelContext: ModelContext
    private nonisolated(unsafe) var notificationTask: Task<Void, Never>?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchRootFolders()
        observeStoreChanges()
    }

    deinit {
        notificationTask?.cancel()
    }

    /// Sentinel-UUID, die `PDFFolder.isVirtual` erkennt. Muss mit dem Wert in `PDFFolder.isVirtual` übereinstimmen.
    private static let virtualFolderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    /// Transientes (nicht persistiertes) Pseudo-Folder, das alle Lektüren aggregiert darstellt.
    /// Die feste Sentinel-UUID stellt sicher, dass `isVirtual` zuverlässig `true` zurückgibt.
    private let allItemsFolder: PDFFolder = PDFFolder(
        name: "Alle Lektüren",
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    )

    func fetchRootFolders() {
        var descriptor = FetchDescriptor<PDFFolder>(
            predicate: #Predicate { $0.parent == nil },
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.relationshipKeyPathsForPrefetching = [\.storedSubfolders, \.items]
        
        do {
            let fetched = try modelContext.fetch(descriptor)
            rootFolders = [allItemsFolder] + fetched
            print("📂 [Fetch] Root-Ordner geladen: \(fetched.count)")
            
            // Items zählen
            let itemDescriptor = FetchDescriptor<PDFItem>()
            let itemCount = try modelContext.fetchCount(itemDescriptor)
            print("📄 [Fetch] Gesamt-Items: \(itemCount)")
            
            // Details zu jedem Ordner
            for folder in fetched {
                let items = folder.items ?? []
                print("📂 [Fetch]   - '\(folder.name ?? "Unbenannt")': \(items.count) Items")
            }
        } catch {
            print("❌ [Fetch] Fehler beim Laden: \(error)")
            rootFolders = [allItemsFolder]
        }
    }

    func addFolder(name: String, parent: PDFFolder?) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newFolder = PDFFolder(name: trimmed, parent: parent)
        modelContext.insert(newFolder)
        try? modelContext.save()
    }

    func importItems(from urls: [URL], into folder: PDFFolder?) {
        // Alle bereits gespeicherten Hashes einmal laden — O(n) statt O(n²).
        let existingHashes = fetchExistingHashes()

        // Ein virtueller Folder (z.B. "Alle Lektüren") wird nicht als Ziel gesetzt.
        let targetFolder: PDFFolder? = folder?.isVirtual == true ? nil : folder
        
        // Settings für AI-Extraktion laden
        // Standardwert ist true, falls noch nie gesetzt
        let defaults = UserDefaults.standard
        let enableAI = defaults.object(forKey: "enableAIExtraction") as? Bool ?? true
        let apiKey = defaults.string(forKey: "claudeAPIKey") ?? ""
        let shouldExtractWithAI = enableAI && !apiKey.isEmpty

        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let hash = sha256(for: url) else { continue }
            guard !existingHashes.contains(hash) else { continue } // Duplikat überspringen

            let fileName = url.lastPathComponent
            let fileSize = fileSizeString(for: url)
            let lastModified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()
            let meta = pdfMetadata(for: url)

            // Datei in den iCloud-Container kopieren (falls iCloud verfügbar).
            // Wenn kein iCloud vorhanden ist, wird die originale URL beibehalten.
            let relativePath: String
            let isCloudFile: Bool
            
            if PDFCloudStorage.isAvailable {
                do {
                    let cloudURL = try PDFCloudStorage.copyToCloud(from: url)
                    // Nur den Dateinamen (letzter Pfad-Komponente) speichern
                    relativePath = cloudURL.lastPathComponent
                    isCloudFile = true
                    print("✅ In iCloud kopiert: \(relativePath)")
                } catch {
                    print("⚠️ iCloud-Kopie fehlgeschlagen für \(fileName): \(error.localizedDescription)")
                    // Fallback: Absolute URL als String speichern
                    relativePath = url.absoluteString
                    isCloudFile = false
                }
            } else {
                // Fallback: Absolute URL als String speichern
                relativePath = url.absoluteString
                isCloudFile = false
                print("ℹ️ iCloud nicht verfügbar, lokale Datei: \(fileName)")
            }

            let item = PDFItem(
                title: meta.title ?? url.deletingPathExtension().lastPathComponent,
                fileName: fileName,
                author: meta.author ?? "",
                subject: meta.subject,
                creator: meta.creator,
                producer: meta.producer,
                keywords: meta.keywords,
                pageCount: meta.pageCount,
                pageWidth: meta.pageWidth,
                pageHeight: meta.pageHeight,
                pageRotation: meta.pageRotation,
                isEncrypted: meta.isEncrypted,
                fileSize: fileSize,
                lastModified: lastModified,
                pdfCreationDate: meta.creationDate,
                pdfModificationDate: meta.modificationDate,
                pdfRelativePath: relativePath,
                isCloudFile: isCloudFile,
                contentHash: hash,
                thumbnailData: meta.thumbnailData
            )
            item.folder = targetFolder
            modelContext.insert(item)
            
            // AI-Extraktion asynchron durchführen, falls aktiviert
            if shouldExtractWithAI, let pdfURL = item.pdfUrl {
                Task {
                    await extractAIMetadata(for: item, from: pdfURL, apiKey: apiKey)
                }
            }
        }
        try? modelContext.save()
    }
    
    /// Extrahiert Metadaten mit Claude AI und aktualisiert das PDFItem.
    /// Diese Methode kann sowohl intern beim Import als auch manuell von der UI aufgerufen werden.
    func extractMetadata(for item: PDFItem) {
        guard let pdfURL = item.pdfUrl else {
            print("⚠️ Keine PDF-URL für Item: \(item.fileName)")
            return
        }
        
        let apiKey = UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""
        guard !apiKey.isEmpty else {
            print("⚠️ Kein Claude API-Schlüssel konfiguriert")
            return
        }
        
        Task {
            await extractAIMetadata(for: item, from: pdfURL, apiKey: apiKey)
        }
    }
    
    /// Extrahiert Metadaten mit Claude AI und aktualisiert das PDFItem.
    private func extractAIMetadata(for item: PDFItem, from url: URL, apiKey: String) async {
        do {
            print("🤖 Starte AI-Extraktion für: \(item.fileName)")
            let metadata = try await ClaudeService.shared.extractMetadata(from: url, apiKey: apiKey)
            
            // Item aktualisieren
            item.aiExtractedTitle = metadata.title
            item.aiExtractedAuthor = metadata.author
            item.aiExtractedDate = metadata.creationDate
            item.aiSummary = metadata.summary
            item.aiKeywords = metadata.keywords
            
            try? modelContext.save()
            print("✅ AI-Extraktion erfolgreich für: \(item.fileName)")
        } catch {
            print("❌ AI-Extraktion fehlgeschlagen für \(item.fileName): \(error.localizedDescription)")
        }
    }

    /// Berechnet den SHA-256-Hash des Dateiinhalts als Hex-String.
    private func sha256(for url: URL) -> String? {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Liest alle bereits gespeicherten Content-Hashes aus dem Store.
    private func fetchExistingHashes() -> Set<String> {
        var descriptor = FetchDescriptor<PDFItem>()
        descriptor.propertiesToFetch = [\.contentHash]
        let items = (try? modelContext.fetch(descriptor)) ?? []
        return Set(items.compactMap { $0.contentHash.isEmpty ? nil : $0.contentHash })
    }

    private func fileSizeString(for url: URL) -> String {
        let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    // Alle PDFKit-Metadaten in einem einzigen Durchgang — PDFDocument wird nur einmal geöffnet.
    private func pdfMetadata(for url: URL) -> PDFMetadata {
        guard let document = PDFDocument(url: url) else { return PDFMetadata() }
        let attrs = document.documentAttributes

        let page0 = document.page(at: 0)
        let bounds = page0?.bounds(for: .mediaBox)

        // Thumbnail
        let thumbnailSize = CGSize(width: 120, height: 160)
        var thumbnailData: Data?
        if let page0, let thumbnail = Optional(page0.thumbnail(of: thumbnailSize, for: .mediaBox)) {
            thumbnailData = thumbnail.jpegData(compressionQuality: 0.7)
        }

        // Keywords: PDFKit liefert entweder [String] oder einen einzelnen String
        var keywords: [String] = []
        if let raw = attrs?[PDFDocumentAttribute.keywordsAttribute] {
            if let array = raw as? [String] {
                keywords = array
            } else if let single = raw as? String {
                keywords = single.components(separatedBy: CharacterSet(charactersIn: ",;")).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            }
        }

        return PDFMetadata(
            title: attrs?[PDFDocumentAttribute.titleAttribute] as? String,
            author: attrs?[PDFDocumentAttribute.authorAttribute] as? String,
            subject: attrs?[PDFDocumentAttribute.subjectAttribute] as? String,
            creator: attrs?[PDFDocumentAttribute.creatorAttribute] as? String,
            producer: attrs?[PDFDocumentAttribute.producerAttribute] as? String,
            keywords: keywords,
            pageCount: document.pageCount,
            pageWidth: bounds.map { Double($0.width) },
            pageHeight: bounds.map { Double($0.height) },
            pageRotation: page0?.rotation,
            isEncrypted: document.isEncrypted,
            creationDate: attrs?[PDFDocumentAttribute.creationDateAttribute] as? Date,
            modificationDate: attrs?[PDFDocumentAttribute.modificationDateAttribute] as? Date,
            thumbnailData: thumbnailData
        )
    }

    func deleteAll() {
        // Zuerst alle iCloud-Dateien entfernen
        let descriptor = FetchDescriptor<PDFItem>()
        if let items = try? modelContext.fetch(descriptor) {
            for item in items {
                if item.isCloudFile, let url = item.pdfUrl {
                    PDFCloudStorage.removeFromCloud(at: url)
                }
            }
        }
        try? modelContext.delete(model: PDFItem.self)
        try? modelContext.delete(model: PDFFolder.self)
        try? modelContext.save()
        selectedFolder = nil
        selectedDetailItem = nil
        fetchRootFolders()
    }

    /// Löscht ein einzelnes Item und – falls vorhanden – die zugehörige iCloud-Datei.
    func delete(item: PDFItem) {
        if item.isCloudFile, let url = item.pdfUrl {
            PDFCloudStorage.removeFromCloud(at: url)
        }
        modelContext.delete(item)
        try? modelContext.save()
    }

    private func observeStoreChanges() {
        notificationTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(
                named: ModelContext.didSave
            )
            for await notification in notifications {
                print("💾 [Sync] ModelContext.didSave empfangen")
                
                // SwiftData verwendet andere Schlüssel als Core Data
                if let userInfo = notification.userInfo {
                    print("💾 [Sync]   UserInfo: \(userInfo.keys)")
                }
                
                await MainActor.run {
                    self?.fetchRootFolders()
                }
            }
        }
    }
}

// MARK: - PDFMetadata

private struct PDFMetadata {
    var title: String?
    var author: String?
    var subject: String?
    var creator: String?
    var producer: String?
    var keywords: [String] = []
    var pageCount: Int = 0
    var pageWidth: Double?
    var pageHeight: Double?
    var pageRotation: Int?
    var isEncrypted: Bool = false
    var creationDate: Date?
    var modificationDate: Date?
    var thumbnailData: Data?
}



