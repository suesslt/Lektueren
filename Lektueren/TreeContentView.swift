//
//  TreeContentView.swift
//  Lektüren
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI
import SwiftData

struct TreeContentView<VM: TreeViewModel>: View
where VM.Folder: Hashable {
    @Bindable var viewModel: VM
    @State private var selection: VM.Folder?
    @State private var isAddingFolder = false

    var body: some View {
        List(viewModel.rootFolders, children: \.subfolders, selection: $selection) { folder in
            NavigationLink(value: folder) {
                let count = folder.isVirtual ? viewModel.totalItemCount : folder.itemCount
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
            // Eindeutigen Identifier für jede Zeile, um korrekte Updates zu erzwingen
            .id(folder.id)
        }
        .onAppear {
            // "Alle Lektüren" beim ersten Start automatisch auswählen
            if selection == nil, let firstFolder = viewModel.rootFolders.first {
                selection = firstFolder
                viewModel.selectedFolder = firstFolder
            }
        }
        .onChange(of: selection) { _, newValue in
            viewModel.selectedFolder = newValue
        }
        .onChange(of: viewModel.selectedFolder) { _, newFolder in
            // Wenn das ViewModel den selectedFolder ändert (z.B. bei deleteAll),
            // müssen wir die UI-Selektion synchronisieren
            if let newFolder, selection?.id != newFolder.id {
                selection = newFolder
            }
        }
        .onChange(of: viewModel.rootFolders) { _, _ in
            // Wenn rootFolders sich ändern, sicherstellen, dass die Selektion noch gültig ist
            if let currentSelection = selection,
               !viewModel.rootFolders.contains(where: { $0.id == currentSelection.id }) {
                // Aktuell selektierter Ordner existiert nicht mehr
                selection = viewModel.rootFolders.first
                viewModel.selectedFolder = selection
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingFolder = true
                } label: {
                    Label("Neuer Ordner", systemImage: "folder.badge.plus")
                }
            }
        }
        .sheet(isPresented: $isAddingFolder) {
            // Ist ein virtueller Ordner selektiert, wird der neue Folder als Root erstellt.
            let effectiveParent: VM.Folder? = viewModel.selectedFolder?.isVirtual == true
                ? nil
                : viewModel.selectedFolder
            AddFolderView(
                parentFolder: effectiveParent,
                onCreate: { name in
                    viewModel.addFolder(name: name, parent: effectiveParent)
                }
            )
        }
    }
}

// MARK: - AddFolderView

private struct AddFolderView<Folder: TreeFolder & Hashable>: View {
    let parentFolder: Folder?
    let onCreate: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var folderName = ""
    @FocusState private var isTextFieldFocused: Bool

    private var trimmedName: String {
        folderName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Ordnername", text: $folderName)
                        .focused($isTextFieldFocused)
                        .onSubmit(submit)
                } header: {
                    if let parent = parentFolder {
                        Text("Unterordner in \"\(parent.name)\"")
                    } else {
                        Text("Neuer Root-Ordner")
                    }
                }
            }
            .navigationTitle("Ordner erstellen")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(!trimmedName.isEmpty)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen", action: submit)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear { isTextFieldFocused = true }
        }
    }

    private func submit() {
        guard !trimmedName.isEmpty else { return }
        onCreate(trimmedName)
        dismiss()
    }
}
