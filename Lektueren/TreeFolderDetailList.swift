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
    @Bindable var viewModel: VM
    @State private var selection: VM.Leaf?
    @State private var isImporting = false
    @State private var isConfirmingDeleteAll = false
    @State private var originalFileDeleteResult: OriginalFileDeleteResult?

    private enum OriginalFileDeleteResult: Identifiable {
        case success(String)
        case notFound(String)
        var id: String {
            switch self {
            case .success(let name): return "success-\(name)"
            case .notFound(let name): return "notfound-\(name)"
            }
        }
    }

    var body: some View {
        contentView
            .searchable(
                text: searchTextBinding,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Titel, Autor, Keywords..."
            )
            .navigationTitle(viewModel.selectedFolder?.name ?? "Ordner wählen")
            .toolbar { toolbarContent }
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
            .alert(
                "Originalfile",
                isPresented: Binding(
                    get: { originalFileDeleteResult != nil },
                    set: { if !$0 { originalFileDeleteResult = nil } }
                ),
                presenting: originalFileDeleteResult
            ) { _ in
                Button("OK", role: .cancel) { originalFileDeleteResult = nil }
            } message: { result in
                originalFileDeleteMessage(result)
            }
    }

    // MARK: - Extracted Views

    @ViewBuilder
    private var contentView: some View {
        if viewModel.selectedFolder != nil {
            let items = viewModel.displayedItems
            if !items.isEmpty {
                itemList(items)
            } else {
                emptyStateView
            }
        } else {
            ContentUnavailableView("Ordner wählen", systemImage: "folder")
        }
    }

    private func itemList(_ items: [VM.Leaf]) -> some View {
        List(items, selection: $selection) { item in
            itemRow(item)
        }
        .onChange(of: selection) { _, newValue in
            viewModel.selectedDetailItem = newValue
        }
    }

    private func itemRow(_ item: VM.Leaf) -> some View {
        NavigationLink(value: item) {
            item.rowView
        }
        .id(item.id)
        .draggable(item.id.uuidString)
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
        .contextMenu { itemContextMenu(item) }
    }

    @ViewBuilder
    private func itemContextMenu(_ item: VM.Leaf) -> some View {
        Button {
            extractAIMetadata(for: item)
        } label: {
            Label("AI-Zusammenfassung neu erstellen", systemImage: "sparkles")
        }

        Divider()

        Button {
            deleteOriginalFile(for: item)
        } label: {
            Label("Originalfile löschen", systemImage: "doc.badge.arrow.up")
        }
        .disabled(!hasOriginalFile(item))

        Divider()

        Button(role: .destructive) {
            deleteItem(item)
        } label: {
            Label("Aus Lektüren löschen", systemImage: "trash")
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if let pdfViewModel = viewModel as? PDFTreeViewModel,
           !pdfViewModel.searchText.isEmpty {
            ContentUnavailableView(
                "Keine Ergebnisse",
                systemImage: "magnifyingglass",
                description: Text("Keine Lektüren gefunden für '\(pdfViewModel.searchText)'")
            )
        } else {
            ContentUnavailableView("Keine Einträge", systemImage: "tray")
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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

    private var searchTextBinding: Binding<String> {
        Binding(
            get: { (viewModel as? PDFTreeViewModel)?.searchText ?? "" },
            set: { (viewModel as? PDFTreeViewModel)?.searchText = $0 }
        )
    }

    private func originalFileDeleteMessage(_ result: OriginalFileDeleteResult) -> Text {
        switch result {
        case .success(let name):
            Text("«\(name)» wurde erfolgreich gelöscht.")
        case .notFound(let name):
            Text("Die Originaldatei «\(name)» existiert nicht mehr.")
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

    private func deleteOriginalFile(for item: VM.Leaf) {
        guard let pdfViewModel = viewModel as? PDFTreeViewModel,
              let pdfItem = item as? PDFItem else {
            return
        }
        let fileName = pdfItem.fileName
        let success = pdfViewModel.deleteOriginalFile(for: pdfItem)
        originalFileDeleteResult = success
            ? .success(fileName)
            : .notFound(fileName)
    }

    private func hasOriginalFile(_ item: VM.Leaf) -> Bool {
        guard let pdfItem = item as? PDFItem else { return false }
        guard let path = pdfItem.sourceFilePath else { return false }
        return FileManager.default.fileExists(atPath: path)
    }
}
