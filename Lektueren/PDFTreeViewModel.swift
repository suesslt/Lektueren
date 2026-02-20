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
import UIKit

/// Minimal ViewModel - Swift Data @Observable Updates propagieren automatisch
@Observable
@MainActor
class PDFTreeViewModel: TreeViewModel {
    typealias Folder = PDFFolder
    typealias Leaf = PDFItem

    var selectedFolder: PDFFolder?
    var selectedDetailItem: PDFItem?
    var searchText: String = ""

    private let modelContext: ModelContext
    
    /// Virtuellerardner für "Alle Lektüren"
    private(set) var allItemsFolder: PDFFolder = PDFFolder(
        name: "Alle Lektüren",
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    )

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Computed Properties
    
    var rootFolders: [PDFFolder] {
        var descriptor = FetchDescriptor<PDFFolder>(
            predicate: #Predicate { $0.parent == nil },
            sortBy: [SortDescriptor(\.name)]
        )
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        return [allItemsFolder] + fetched
    }
    
    var displayedItems: [PDFItem] {
        guard let folder = selectedFolder else { return [] }
        
        let items: [PDFItem]
        if folder.isVirtual {
            var descriptor = FetchDescriptor<PDFItem>(sortBy: [SortDescriptor(\.title)])
            items = (try? modelContext.fetch(descriptor)) ?? []
        } else {
            let folderID = folder.id
            var descriptor = FetchDescriptor<PDFItem>(
                predicate: #Predicate<PDFItem> { $0.folder?.id == folderID },
                sortBy: [SortDescriptor(\.title)]
            )
            items = (try? modelContext.fetch(descriptor)) ?? []
        }
        
        return searchText.isEmpty ? items : items.filter { matchesSearchText($0) }
    }
    
    var totalItemCount: Int {
        (try? modelContext.fetchCount(FetchDescriptor<PDFItem>())) ?? 0
    }
    
    // MARK: - Actions
    
    func addFolder(name: String, parent: PDFFolder?) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newFolder = PDFFolder(name: trimmed, parent: parent)
        modelContext.insert(newFolder)
        try? modelContext.save()
    }
    
    func fetchRootFolders() {
        // Nicht benötigt - computed property
    }
    
    func importItems(from urls: [URL], into folder: PDFFolder?) {
        let existingHashes = fetchExistingHashes()
        let targetFolder: PDFFolder? = folder?.isVirtual == true ? nil : folder
        
        let defaults = UserDefaults.standard
        let enableAI = defaults.object(forKey: "enableAIExtraction") as? Bool ?? true
        let apiKey = defaults.string(forKey: "claudeAPIKey") ?? ""
        let shouldExtractWithAI = enableAI && !apiKey.isEmpty

        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let hash = sha256(for: url) else { continue }
            guard !existingHashes.contains(hash) else { continue }

            let fileName = url.lastPathComponent
            let fileSize = fileSizeString(for: url)
            let lastModified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()
            let meta = pdfMetadata(for: url)

            let (relativePath, isCloudFile) = copyToCloudIfAvailable(url: url, fileName: fileName)

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
            
            if shouldExtractWithAI, let pdfURL = item.pdfUrl {
                Task {
                    await extractAIMetadata(for: item, from: pdfURL, apiKey: apiKey)
                }
            }
        }
        try? modelContext.save()
    }
    
    func delete(item: PDFItem) {
        if item.isCloudFile, let url = item.pdfUrl {
            PDFCloudStorage.removeFromCloud(at: url)
        }
        modelContext.delete(item)
        try? modelContext.save()
    }
    
    func deleteAll() {
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
        
        selectedDetailItem = nil
        selectedFolder = allItemsFolder
    }
    
    func extractMetadata(for item: PDFItem) {
        guard let pdfURL = item.pdfUrl else { return }
        let apiKey = UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""
        guard !apiKey.isEmpty else { return }
        
        Task {
            await extractAIMetadata(for: item, from: pdfURL, apiKey: apiKey)
        }
    }
    
    // MARK: - Private Helpers
    
    private func matchesSearchText(_ item: PDFItem) -> Bool {
        let searchLower = searchText.lowercased()
        return [item.title, item.aiExtractedTitle, item.author, item.aiExtractedAuthor, 
                item.fileName, item.subject, item.creator, item.producer, item.aiSummary]
            .compactMap { $0 }
            .contains(where: { $0.lowercased().contains(searchLower) })
            || (item.keywords + item.aiKeywords).contains(where: { $0.lowercased().contains(searchLower) })
    }
    
    private func extractAIMetadata(for item: PDFItem, from url: URL, apiKey: String) async {
        do {
            let metadata = try await ClaudeService.shared.extractMetadata(from: url, apiKey: apiKey)
            item.aiExtractedTitle = metadata.title
            item.aiExtractedAuthor = metadata.author
            item.aiExtractedDate = metadata.creationDate
            item.aiSummary = metadata.summary
            item.aiKeywords = metadata.keywords
            try? modelContext.save()
        } catch {
            print("❌ AI-Extraktion fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    private func sha256(for url: URL) -> String? {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

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
    
    private func copyToCloudIfAvailable(url: URL, fileName: String) -> (String, Bool) {
        guard PDFCloudStorage.isAvailable else {
            return (url.absoluteString, false)
        }
        
        do {
            let cloudURL = try PDFCloudStorage.copyToCloud(from: url)
            return (cloudURL.lastPathComponent, true)
        } catch {
            print("⚠️ iCloud-Kopie fehlgeschlagen: \(error.localizedDescription)")
            return (url.absoluteString, false)
        }
    }

    private func pdfMetadata(for url: URL) -> PDFMetadata {
        guard let document = PDFDocument(url: url) else { return PDFMetadata() }
        let attrs = document.documentAttributes
        let page0 = document.page(at: 0)
        let bounds = page0?.bounds(for: .mediaBox)

        let thumbnailSize = CGSize(width: 120, height: 160)
        var thumbnailData: Data?
        if let page0, let thumbnail = Optional(page0.thumbnail(of: thumbnailSize, for: .mediaBox)) {
            thumbnailData = thumbnail.jpegData(compressionQuality: 0.7)
        }

        var keywords: [String] = []
        if let raw = attrs?[PDFDocumentAttribute.keywordsAttribute] {
            if let array = raw as? [String] {
                keywords = array
            } else if let single = raw as? String {
                keywords = single.components(separatedBy: CharacterSet(charactersIn: ",;"))
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
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
