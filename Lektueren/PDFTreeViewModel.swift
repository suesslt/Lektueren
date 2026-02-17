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
    var selectedFolder: PDFFolder? {
        didSet { refreshDisplayedItems() }
    }
    var selectedDetailItem: PDFItem?
    private(set) var displayedItems: [PDFItem] = []

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

    private let allItemsFolder: PDFFolder = PDFFolder(
        name: "Alle Lektüren",
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    )

    func fetchRootFolders() {
        let pseudoID = allItemsFolder.id
        var descriptor = FetchDescriptor<PDFFolder>(
            predicate: #Predicate { $0.parent == nil && $0.id != pseudoID },
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.relationshipKeyPathsForPrefetching = [\.storedSubfolders, \.items]
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        rootFolders = [allItemsFolder] + fetched
        refreshDisplayedItems()
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

    /// Aktualisiert `displayedItems` basierend auf dem aktuell selektierten Folder.
    /// - Virtueller Folder ("Alle Lektüren"): Query über alle PDFItems im Store.
    /// - Echter Folder: Items direkt aus dem Folder.
    /// - Kein Folder: leere Liste.
    private func refreshDisplayedItems() {
        guard let folder = selectedFolder else {
            displayedItems = []
            return
        }
        if folder.isVirtual {
            let descriptor = FetchDescriptor<PDFItem>(
                sortBy: [SortDescriptor(\.title)]
            )
            displayedItems = (try? modelContext.fetch(descriptor)) ?? []
        } else {
            displayedItems = folder.items ?? []
        }
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

