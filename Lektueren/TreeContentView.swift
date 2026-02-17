//
//  TreeContentView.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct TreeContentView<VM: TreeViewModel>: View
where VM.Folder: Hashable {
    @State var viewModel: VM
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
        }
        .onChange(of: selection) { _, newValue in
            viewModel.selectedFolder = newValue
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
            #if os(iOS) || targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
