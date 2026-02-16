//
//  TripleColumnLayout.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct TripleColumnLayout<VM: TreeViewModel, Detail: View>: View
    where VM.Folder: Hashable, VM.Leaf: Hashable
{
    // @Observable-kompatibel: @State statt @StateObject
    @State var viewModel: VM
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    let detail: (VM.Leaf) -> Detail

    init(viewModel: VM, @ViewBuilder detail: @escaping (VM.Leaf) -> Detail) {
        _viewModel = State(wrappedValue: viewModel)
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
                Text("Bitte wählen Sie ein Element aus.")
            }
        }
    }
}
