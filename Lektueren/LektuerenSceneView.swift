//
//  LektuerenSceneView.swift
//  Lektüren
//
//  Scene für den PDF/Lektüren-Bereich.
//  NavigationSplitView mit Ordner-Sidebar, Dokumentliste und PDF-Detail.
//

import SwiftUI

struct LektuerenSceneView: View {
    var viewModel: PDFTreeViewModel
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
                .navigationTitle("Lektüren")
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
                PDFDetailView(item: item)
            } else {
                Text("Bitte wählen Sie eine Lektüre aus.")
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .onAppear {
            columnVisibility = .all
        }
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebarContent: some View {
        List {
            Section("Ordner") {
                ForEach(viewModel.rootFolders, id: \.id) { folder in
                    pdfFolderRow(folder)
                }
            }
        }
    }

    private func pdfFolderRow(_ folder: PDFFolder) -> some View {
        let isSelected = viewModel.selectedFolder?.id == folder.id
        let count = folder.isVirtual ? viewModel.totalItemCount : folder.itemCount
        return Button {
            viewModel.selectedFolder = folder
        } label: {
            HStack {
                Label(folder.name, systemImage: folder.icon)
                Spacer()
                if count > 0 {
                    Text("\(count)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .foregroundStyle(isSelected ? .primary : .secondary)
        .listRowBackground(
            isSelected ? Color.accentColor.opacity(0.15) : Color.clear
        )
    }
}
