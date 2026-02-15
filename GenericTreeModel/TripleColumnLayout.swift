//
//  TripleColumnLayout.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct TripleColumnLayout<VM: TreeViewModel>: View where VM.Item: DetailDisplayable {
    @StateObject var viewModel: VM
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            TreeContentView(viewModel: viewModel)
                .navigationTitle("Bibliothek")
        } content: {
            TreeFolderDetailList(viewModel: viewModel)
        } detail: {
            if let item = viewModel.selectedDetailItem {
                GenericDetailView(item: item)
            } else {
                Text("Bitte wählen Sie ein Element aus.")
            }
        }
    }
}
