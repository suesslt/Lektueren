//
//  TreeContentView.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct TreeContentView<VM: TreeViewModel>: View {
    @ObservedObject var viewModel: VM
    @State private var selection: VM.Item?

    var body: some View {
        List(viewModel.rootFolders, children: \.children, selection: $selection) { item in
            NavigationLink(value: item) {
                Label(item.name, systemImage: item.icon)
            }
        }
        .onChange(of: selection) { _, newValue in
            viewModel.selectedFolder = newValue
        }
    }
}
