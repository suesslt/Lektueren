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
    @ObservedObject var viewModel: VM
    @State private var selection: VM.Leaf?

    var body: some View {
        if let folder = viewModel.selectedFolder, let items = folder.items, !items.isEmpty {
            List(items, selection: $selection) { item in
                NavigationLink(value: item) {
                    Label(item.name, systemImage: item.icon)
                }
            }
            .navigationTitle(folder.name)
            .onChange(of: selection) { _, newValue in
                viewModel.selectedDetailItem = newValue
            }
        } else {
            ContentUnavailableView("Ordner wählen", systemImage: "folder")
        }
    }
}
