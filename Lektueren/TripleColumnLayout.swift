//
//  TripleColumnLayout.swift
//  Lektüren
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct TripleColumnLayout<VM: TreeViewModel, Detail: View>: View
    where VM.Folder: Hashable, VM.Leaf: Hashable
{
    @Bindable var viewModel: VM
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showingSettings = false

    let detail: (VM.Leaf) -> Detail

    init(viewModel: VM, @ViewBuilder detail: @escaping (VM.Leaf) -> Detail) {
        _viewModel = Bindable(wrappedValue: viewModel)
        self.detail = detail
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            TreeContentView(viewModel: viewModel)
                .navigationTitle("Bibliothek")
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Einstellungen", systemImage: "gear")
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
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
