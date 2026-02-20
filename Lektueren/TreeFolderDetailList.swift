//
//  TreeFolderDetailList.swift
//  Lektüren
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI
import UniformTypeIdentifiers

struct TreeFolderDetailList<VM: TreeViewModel>: View
    where VM.Leaf: Hashable
{
    var viewModel: VM
    @State private var selection: VM.Leaf?
    @State private var isImporting = false
    @State private var isConfirmingDeleteAll = false

    var body: some View {
        let title = viewModel.selectedFolder?.name ?? "Ordner wählen"

        Group {
            if viewModel.selectedFolder != nil {
                let items = viewModel.displayedItems
                if !items.isEmpty {
                    List(items, selection: $selection) { item in
                        NavigationLink(value: item) {
                            item.rowView
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteItem(item)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                extractAIMetadata(for: item)
                            } label: {
                                Label("AI-Extraktion", systemImage: "sparkles")
                            }
                            .tint(.purple)
                        }
                    }
                    .onChange(of: selection) { _, newValue in
                        viewModel.selectedDetailItem = newValue
                    }
                } else {
                    ContentUnavailableView("Keine Einträge", systemImage: "tray")
                }
            } else {
                ContentUnavailableView("Ordner wählen", systemImage: "folder")
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isImporting = true
                } label: {
                    Label("PDFs importieren", systemImage: "document.badge.plus")
                }
                .disabled(viewModel.selectedFolder == nil)
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    isConfirmingDeleteAll = true
                } label: {
                    Label("Alles löschen", systemImage: "trash")
                }
            }
        }
        .confirmationDialog(
            "Alle Daten löschen?",
            isPresented: $isConfirmingDeleteAll,
            titleVisibility: .visible
        ) {
            Button("Alle Ordner und Lektüren löschen", role: .destructive) {
                viewModel.deleteAll()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Dieser Vorgang löscht alle Ordner und Lektüren unwiderruflich.")
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                viewModel.importItems(from: urls, into: viewModel.selectedFolder)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteItem(_ item: VM.Leaf) {
        guard let pdfViewModel = viewModel as? PDFTreeViewModel,
              let pdfItem = item as? PDFItem else {
            return
        }
        pdfViewModel.delete(item: pdfItem)
    }
    
    private func extractAIMetadata(for item: VM.Leaf) {
        guard let pdfViewModel = viewModel as? PDFTreeViewModel,
              let pdfItem = item as? PDFItem else {
            return
        }
        pdfViewModel.extractMetadata(for: pdfItem)
    }
}
