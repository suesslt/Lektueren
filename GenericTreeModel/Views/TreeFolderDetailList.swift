//
//  TreeFolderDetailList.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct TreeFolderDetailList<VM: TreeViewModel>: View {
    @ObservedObject var viewModel: VM
    @State private var selection: VM.Item?

    var body: some View {
        if let selected = viewModel.selectedFolder, let children = selected.children {
            List(children, selection: $selection) { child in
                NavigationLink(value: child) {
                    Text(child.name)
                }
            }
            .navigationTitle(selected.name)
            .onChange(of: selection) { _, newValue in
                viewModel.selectedDetailItem = newValue
            }
        } else {
            ContentUnavailableView("Ordner wählen", systemImage: "folder")
        }
    }
}
