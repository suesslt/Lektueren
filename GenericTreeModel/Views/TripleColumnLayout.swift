//
//  TripleColumnLayout.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct TripleColumnLayout<ViewModel: TreeViewModel>: View where ViewModel.Item: TreeItem {
    @StateObject var viewModel: ViewModel
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            TreeContentView(viewModel: viewModel)
                .navigationTitle("Bibliothek")
        } content: {
            TreeFolderDetailList(viewModel: viewModel)
        } detail: {
            if let item = viewModel.selectedDetailItem {
                PDFDetailView(item: item)
            } else {
                Text("Bitte wählen Sie ein Element aus.")
            }
        }
    }
}
