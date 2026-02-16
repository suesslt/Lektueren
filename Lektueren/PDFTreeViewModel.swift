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
    nonisolated(unsafe) private var notificationTask: Task<Void, Never>?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchRootFolders()
        observeStoreChanges()
    }

    deinit {
        notificationTask?.cancel()
    }

    // MARK: - Fetch

    func fetchRootFolders() {
        var descriptor = FetchDescriptor<PDFFolder>(
            predicate: #Predicate { $0.parent == nil },
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.relationshipKeyPathsForPrefetching = [\.subfolders, \.items]
        rootFolders = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Live-Updates

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

