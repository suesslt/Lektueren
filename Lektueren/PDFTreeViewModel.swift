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

    private let allItemsFolder: PDFFolder = PDFFolder(name: "Alle Lektüren") // Ein transientes (nicht persistiertes) Pseudo-Folder, das alle Lektüren aggregiert darstellt.

    func fetchRootFolders() {
        var descriptor = FetchDescriptor<PDFFolder>(
            predicate: #Predicate { $0.parent == nil },
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.relationshipKeyPathsForPrefetching = [\.subfolders, \.items]
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

