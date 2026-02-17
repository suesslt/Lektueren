//
//  TreeFolderDetailList.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI
import UniformTypeIdentifiers

struct TreeFolderDetailList<VM: TreeViewModel>: View
    where VM.Leaf: Hashable
{
    var viewModel: VM
    @State private var selection: VM.Leaf?
    @State private var isImporting = false

    var body: some View {
        let title = viewModel.selectedFolder?.name ?? "Ordner wählen"

        Group {
            if viewModel.selectedFolder != nil {
                let items = viewModel.displayedItems
                if !items.isEmpty {
                    List(items, selection: $selection) { item in
                        NavigationLink(value: item) {
                            item.rowView
                        }
                    }
                    .onChange(of: selection) { _, newValue in
                        viewModel.selectedDetailItem = newValue
                    }
                } else {
                    ContentUnavailableView("Keine Einträge", systemImage: "tray")
                }
            } else {
                ContentUnavailableView("Ordner wählen", systemImage: "folder")
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isImporting = true
                } label: {
                    Label("PDFs importieren", systemImage: "document.badge.plus")
                }
                .disabled(
                    viewModel.selectedFolder == nil ||
                    viewModel.selectedFolder?.isVirtual == true
                )
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            guard let folder = viewModel.selectedFolder else { return }
            if case .success(let urls) = result {
                viewModel.importItems(from: urls, into: folder)
            }
        }
    }
}
