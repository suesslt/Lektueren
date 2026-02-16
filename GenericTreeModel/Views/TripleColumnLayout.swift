//
//  TripleColumnLayout.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct TripleColumnLayout<ViewModel: TreeViewModel, Detail: View>: View where ViewModel.Item: TreeFolder {
    @StateObject var viewModel: ViewModel
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    let detail: (ViewModel.Item) -> Detail

    init(viewModel: ViewModel, @ViewBuilder detail: @escaping (ViewModel.Item) -> Detail) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.detail = detail
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            TreeContentView(viewModel: viewModel)
                .navigationTitle("Bibliothek")
        } content: {
            TreeFolderDetailList(viewModel: viewModel)
        } detail: {
            if let item = viewModel.selectedDetailItem {
                detail(item)
            } else {
                ContentUnavailableView("Element auswählen", systemImage: "folder")
            }
        }
    }
}
