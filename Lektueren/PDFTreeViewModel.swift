//
//  PDFTreeViewModel.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI
import SwiftData

/// Observable ViewModel, das Folder und PDFs direkt
/// aus dem SwiftData / CloudKit Store liest.
@Observable
class PDFTreeViewModel: TreeViewModel {
    typealias Folder = PDFFolder
    typealias Leaf = PDFItem

    /// Alle Root-Folder (ohne Parent) – wird von der View gesetzt.
    var rootFolders: [PDFFolder] = []
    var selectedFolder: PDFFolder?
    var selectedDetailItem: PDFItem?

    // MARK: - Helpers

    /// Gibt alle PDFItems aus einem Folder-Baum rekursiv zurück.
    func allItems(in folders: [PDFFolder]) -> [PDFItem] {
        folders.flatMap { folder -> [PDFItem] in
            let ownItems = folder.items ?? []
            let childItems = allItems(in: folder.subfolders ?? [])
            return ownItems + childItems
        }
    }
}
// MARK: - SwiftUI View Helper

/// Diese View liest Folder und Items per @Query aus CloudKit/SwiftData
/// und übergibt sie an den PDFTreeViewModel.
struct PDFTreeDataProvider<Content: View>: View {

    /// Nur Root-Folder (parent == nil), alphabetisch sortiert.
    @Query(
        filter: #Predicate<PDFFolder> { $0.parent == nil },
        sort: [SortDescriptor(\PDFFolder.name)]
    )
    private var rootFolders: [PDFFolder]

    /// Alle PDFItems, sortiert nach Titel.
    @Query(sort: \PDFItem.title)
    private var allPDFItems: [PDFItem]

    @State private var viewModel = PDFTreeViewModel()
    let content: (PDFTreeViewModel) -> Content

    var body: some View {
        content(viewModel)
            .onChange(of: rootFolders, initial: true) { _, newFolders in
                viewModel.rootFolders = newFolders
            }
    }
}

