//
//  TreeContentView.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct TreeContentView<VM: TreeViewModel>: View
    where VM.Folder: Hashable
{
    @State var viewModel: VM
    @State private var selection: VM.Folder?

    var body: some View {
        List(viewModel.rootFolders, children: \.subfolders, selection: $selection) { folder in
            NavigationLink(value: folder) {
                Label(folder.name, systemImage: folder.icon)
            }
        }
        .onChange(of: selection) { _, newValue in
            viewModel.selectedFolder = newValue
        }
    }
}

