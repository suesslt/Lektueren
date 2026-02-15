//
//  TreeFolderDetailList.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct TreeFolderDetailList<VM: TreeViewModel>: View {
    @ObservedObject var viewModel: VM
    
    var body: some View {
        if let selected = viewModel.selectedFolder, let children = selected.children {
            List(children, selection: $viewModel.selectedDetailItem) { child in
                NavigationLink(value: child) {
                    Text(child.name)
                }
            }
            .navigationTitle(selected.name)
        } else {
            ContentUnavailableView("Ordner wählen", systemImage: "folder")
        }
    }
}
