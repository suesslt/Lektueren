//
//  TreeContentView.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct TreeContentView<VM: TreeViewModel>: View {
    @ObservedObject var viewModel: VM
    
    var body: some View {
        // Die reine Liste mit Baum-Funktionalität
        List(viewModel.rootFolders, children: \.children, selection: $viewModel.selectedFolder) { item in
            NavigationLink(value: item) {
                Label(item.name, systemImage: item.icon)
            }
        }
    }
}
