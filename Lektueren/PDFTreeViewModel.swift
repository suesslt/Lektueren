//
//  PDFTreeViewModel.swift
//  GenericTreeModel
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
        guard let folder = selectedFolder else { return [] }
        if folder.isVirtual {
            var descriptor = FetchDescriptor<PDFItem>(sortBy: [SortDescriptor(\.title)])
            return (try? modelContext.fetch(descriptor)) ?? []
        }
        return folder.items ?? []
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
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        rootFolders = [allItemsFolder] + fetched
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

        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let hash = sha256(for: url) else { continue }
            guard !existingHashes.contains(hash) else { continue } // Duplikat überspringen

            let fileName = url.lastPathComponent
            let fileSize = fileSizeString(for: url)
            let lastModified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()
            let pageCount = pdfPageCount(for: url)
            let thumbnailData = pdfThumbnailData(for: url)

            let item = PDFItem(
                title: url.deletingPathExtension().lastPathComponent,
                fileName: fileName,
                pageCount: pageCount,
                fileSize: fileSize,
                lastModified: lastModified,
                pdfUrl: url,
                contentHash: hash,
                thumbnailData: thumbnailData
            )
            item.folder = targetFolder
            modelContext.insert(item)
        }
        try? modelContext.save()
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

    private func pdfPageCount(for url: URL) -> Int {
        PDFDocument(url: url)?.pageCount ?? 0
    }

    private func pdfThumbnailData(for url: URL, size: CGSize = CGSize(width: 120, height: 160)) -> Data? {
        guard
            let document = PDFDocument(url: url),
            let page = document.page(at: 0)
        else { return nil }
        let thumbnail = page.thumbnail(of: size, for: .mediaBox)
        #if os(macOS)
        return thumbnail.tiffRepresentation
        #else
        return thumbnail.jpegData(compressionQuality: 0.7)
        #endif
    }

    func deleteAll() {
        try? modelContext.delete(model: PDFItem.self)
        try? modelContext.delete(model: PDFFolder.self)
        try? modelContext.save()
        selectedFolder = nil
        selectedDetailItem = nil
        fetchRootFolders()
    }

    private func observeStoreChanges() {
        notificationTask = Task { [weak self] in
            // Lauscht auf alle SwiftData-Änderungen im zugehörigen ModelContainer.
            let notifications = NotificationCenter.default.notifications(
                named: ModelContext.didSave
            )
            for await _ in notifications {
                self?.fetchRootFolders()
            }
        }
    }
}

