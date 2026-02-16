//
//  TreeFolderDetailList.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct TreeFolderDetailList<VM: TreeViewModel>: View
    where VM.Leaf: Hashable
{
    var viewModel: VM
    @State private var selection: VM.Leaf?

    var body: some View {
        let title = viewModel.selectedFolder?.name ?? "Ordner wählen"

        Group {
            if let folder = viewModel.selectedFolder,
               let items = folder.items, !items.isEmpty {
                List(items, selection: $selection) { item in
                    NavigationLink(value: item) {
                        item.rowView
                    }
                }
                .onChange(of: selection) { _, newValue in
                    viewModel.selectedDetailItem = newValue
                }
            } else if viewModel.selectedFolder != nil {
                ContentUnavailableView("Keine Einträge", systemImage: "tray")
            } else {
                ContentUnavailableView("Ordner wählen", systemImage: "folder")
            }
        }
        .navigationTitle(title)
    }
}
