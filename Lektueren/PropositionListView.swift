//
//  PropositionListView.swift
//  Lektüren
//
//  Mittlere Spalte (Content) für die Propositionen-Ansicht.
//  Zeigt eine Liste aller Propositionen mit Suche, CSV-Import/Export und Notes-Import.
//

import SwiftUI
import UniformTypeIdentifiers

struct PropositionListView: View {
    @Bindable var viewModel: PropositionViewModel
    @State private var isImportingCSV = false
    @State private var isImportingNotes = false
    @State private var isExportingCSV = false
    @State private var isAddingProposition = false
    @State private var isConfirmingDeleteAll = false
    @State private var csvDocument = CSVDocument()
    @State private var importError: String?

    var body: some View {
        contentView
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Kernaussage durchsuchen..."
            )
            .navigationTitle(navigationTitle)
            .toolbar { toolbarContent }
            .modifier(PropositionImportModifiers(
                isImportingCSV: $isImportingCSV,
                isImportingNotes: $isImportingNotes,
                isExportingCSV: $isExportingCSV,
                isAddingProposition: $isAddingProposition,
                isConfirmingDeleteAll: $isConfirmingDeleteAll,
                csvDocument: $csvDocument,
                importError: $importError,
                viewModel: viewModel
            ))
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        let items = viewModel.displayedPropositions
        if !items.isEmpty {
            propositionList(items)
        } else if viewModel.isImporting {
            importingView
        } else if !viewModel.searchText.isEmpty {
            noResultsView
        } else {
            emptyView
        }
    }

    private func propositionList(_ items: [Proposition]) -> some View {
        List(selection: Binding(
            get: { viewModel.selectedProposition?.id },
            set: { newID in
                viewModel.selectedProposition = newID.flatMap { id in
                    items.first { $0.id == id }
                }
            }
        )) {
            ForEach(items) { proposition in
                PropositionRowView(proposition: proposition)
                    .tag(proposition.id)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteProposition(proposition)
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
            }
        }
    }

    private var importingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(viewModel.importProgress)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var noResultsView: some View {
        ContentUnavailableView(
            "Keine Ergebnisse",
            systemImage: "magnifyingglass",
            description: Text("Keine Propositionen gefunden für '\(viewModel.searchText)'")
        )
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "Keine Propositionen",
            systemImage: "text.quote",
            description: Text("Importiere Notizen oder CSV-Dateien um Propositionen zu erstellen.")
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    isAddingProposition = true
                } label: {
                    Label("Neue Proposition", systemImage: "plus")
                }

                Divider()

                Button {
                    isImportingNotes = true
                } label: {
                    Label("Notizen importieren (Markdown)", systemImage: "note.text")
                }

                Button {
                    isImportingCSV = true
                } label: {
                    Label("CSV importieren", systemImage: "square.and.arrow.down")
                }

                Divider()

                Button {
                    csvDocument = CSVDocument(content: viewModel.exportCSV())
                    isExportingCSV = true
                } label: {
                    Label("CSV exportieren", systemImage: "square.and.arrow.up")
                }
                .disabled(viewModel.totalCount == 0)
            } label: {
                Label("Aktionen", systemImage: "ellipsis.circle")
            }
        }

        ToolbarItem(placement: .destructiveAction) {
            Button(role: .destructive) {
                isConfirmingDeleteAll = true
            } label: {
                Label("Alles löschen", systemImage: "trash")
            }
            .disabled(viewModel.totalCount == 0)
        }
    }

    // MARK: - Helpers

    private var navigationTitle: String {
        viewModel.selectedCategory ?? "Alle Propositionen"
    }
}

// MARK: - Import/Export Modifiers (getrennt, um SwiftUI fileImporter-Konflikte zu vermeiden)

private struct PropositionImportModifiers: ViewModifier {
    @Binding var isImportingCSV: Bool
    @Binding var isImportingNotes: Bool
    @Binding var isExportingCSV: Bool
    @Binding var isAddingProposition: Bool
    @Binding var isConfirmingDeleteAll: Bool
    @Binding var csvDocument: CSVDocument
    @Binding var importError: String?
    var viewModel: PropositionViewModel

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Alle Propositionen löschen?",
                isPresented: $isConfirmingDeleteAll,
                titleVisibility: .visible
            ) {
                Button("Alle Propositionen löschen", role: .destructive) {
                    viewModel.deleteAll()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Dieser Vorgang löscht alle Propositionen unwiderruflich.")
            }
            // CSV-Import auf einem Background-View, um Konflikte mit Notes-Import zu vermeiden
            .background {
                Color.clear
                    .fileImporter(
                        isPresented: $isImportingCSV,
                        allowedContentTypes: [.commaSeparatedText],
                        allowsMultipleSelection: false
                    ) { result in
                        handleCSVImport(result)
                    }
            }
            // Notes-Import auf einem separaten Overlay-View
            .overlay {
                Color.clear
                    .allowsHitTesting(false)
                    .fileImporter(
                        isPresented: $isImportingNotes,
                        allowedContentTypes: [.folder],
                        allowsMultipleSelection: false
                    ) { result in
                        handleNotesImport(result)
                    }
            }
            .fileExporter(
                isPresented: $isExportingCSV,
                document: csvDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "Propositionen.csv"
            ) { _ in }
            .alert("Import-Fehler", isPresented: showImportError) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
            .sheet(isPresented: $isAddingProposition) {
                AddPropositionView { keyMessage, subject in
                    viewModel.addProposition(keyMessage: keyMessage, subject: subject)
                }
            }
    }

    private var showImportError: Binding<Bool> {
        Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )
    }

    private func handleCSVImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        Task {
            await viewModel.importCSV(from: url)
        }
    }

    private func handleNotesImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        Task {
            await viewModel.importFromNotes(folderURL: url)
        }
    }
}

// MARK: - AddPropositionView

private struct AddPropositionView: View {
    let onCreate: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var keyMessage = ""
    @State private var subject = Proposition.allSubjects[0]
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Kernaussage") {
                    TextEditor(text: $keyMessage)
                        .focused($isTextFieldFocused)
                        .frame(minHeight: 100)
                }

                Section("Kategorie") {
                    Picker("Kategorie", selection: $subject) {
                        ForEach(Proposition.allSubjects, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                }
            }
            .navigationTitle("Neue Proposition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") {
                        let trimmed = keyMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onCreate(trimmed, subject)
                        dismiss()
                    }
                    .disabled(keyMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { isTextFieldFocused = true }
        }
    }
}
