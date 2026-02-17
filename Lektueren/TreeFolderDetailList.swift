//
//  TreeFolderDetailList.swift
//  GenericTreeModel
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
    #if DEBUG
    @State private var isConfirmingDeleteAll = false
    #endif

    var body: some View {
        let title = viewModel.selectedFolder?.name ?? "Ordner wählen"

        Group {
            if let folder = viewModel.selectedFolder,
               let items = folder.items, !items.isEmpty {
                List(items, selection: $selection) { item in
                    NavigationLink(value: item) {
                        item.rowView
                    }
                }
                .onChange(of: selection) { _, newValue in
                    viewModel.selectedDetailItem = newValue
                }
            } else if viewModel.selectedFolder != nil {
                ContentUnavailableView("Keine Einträge", systemImage: "tray")
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
            #if DEBUG
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    isConfirmingDeleteAll = true
                } label: {
                    Label("Alles löschen", systemImage: "trash")
                }
            }
            #endif
        }
        #if DEBUG
        .confirmationDialog(
            "Alles löschen?",
            isPresented: $isConfirmingDeleteAll,
            titleVisibility: .visible
        ) {
            Button("Alle Folders und Items löschen", role: .destructive) {
                viewModel.deleteAll()
                selection = nil
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Diese Aktion löscht alle Ordner und Einträge unwiderruflich. Nur für Entwicklungszwecke.")
        }
        #endif
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            guard let folder = viewModel.selectedFolder else { return }
            if case .success(let urls) = result {
                viewModel.importItems(from: urls, into: folder)
            }
        }
    }
}
