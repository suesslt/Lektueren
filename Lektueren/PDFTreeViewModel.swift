//
//  PDFTreeViewModel.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI
import SwiftData

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

    // Ein transientes (nicht persistiertes) Pseudo-Folder mit fixer ID,
    // damit SwiftUI nie ein Duplikat sieht, egal wie oft fetchRootFolders() läuft.
    private let allItemsFolder: PDFFolder = PDFFolder(
        name: "Alle Lektüren",
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    )

    func fetchRootFolders() {
        let pseudoID = allItemsFolder.id
        var descriptor = FetchDescriptor<PDFFolder>(
            // Schliesst das Pseudo-Folder aus, falls SwiftData es verfolgt,
            // und holt nur echte Root-Ordner (parent == nil).
            predicate: #Predicate { $0.parent == nil && $0.id != pseudoID },
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

    func importItems(from urls: [URL], into folder: PDFFolder) {
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }

            let fileName = url.lastPathComponent
            let fileSize = fileSizeString(for: url)
            let lastModified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()

            let item = PDFItem(
                title: url.deletingPathExtension().lastPathComponent,
                fileName: fileName,
                fileSize: fileSize,
                lastModified: lastModified,
                pdfUrl: url
            )
            item.folder = folder
            modelContext.insert(item)
        }
        try? modelContext.save()
    }

    private func fileSizeString(for url: URL) -> String {
        let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    #if DEBUG
    func deleteAll() {
        try? modelContext.delete(model: PDFItem.self)
        try? modelContext.delete(model: PDFFolder.self)
        try? modelContext.save()
        selectedFolder = nil
        selectedDetailItem = nil
        fetchRootFolders()
    }
    #endif

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

