//
//  PropositionDetailView.swift
//  Lektüren
//
//  Bearbeitbare Detailansicht für eine Proposition.
//

import SwiftUI

struct PropositionDetailView: View {
    @Bindable var proposition: Proposition
    let onSave: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Form {
            Section("Kernaussage") {
                TextEditor(text: $proposition.keyMessage)
                    .frame(minHeight: 120)
                    .onChange(of: proposition.keyMessage) { _, _ in onSave() }
            }

            Section("Kategorie") {
                Picker("Kategorie", selection: $proposition.subject) {
                    ForEach(Proposition.allSubjects, id: \.self) { subject in
                        Label(subject, systemImage: iconForSubject(subject))
                            .tag(subject)
                    }
                }
                .onChange(of: proposition.subject) { _, _ in onSave() }
            }

            Section("Details") {
                DatePicker(
                    "Datum der Proposition",
                    selection: Binding(
                        get: { proposition.dateOfProposition ?? Date() },
                        set: { proposition.dateOfProposition = $0; onSave() }
                    ),
                    displayedComponents: .date
                )

                if proposition.dateOfProposition != nil {
                    Button("Datum entfernen", role: .destructive) {
                        proposition.dateOfProposition = nil
                        onSave()
                    }
                    .font(.caption)
                }

                TextField("Quelle", text: $proposition.source)
                    .onChange(of: proposition.source) { _, _ in onSave() }

                TextField("Notiz-Titel", text: $proposition.noteTitle)
                    .onChange(of: proposition.noteTitle) { _, _ in onSave() }
            }

            Section("Metadaten") {
                LabeledContent("Erstellt am") {
                    Text(proposition.createdAt.formatted(date: .long, time: .shortened))
                }
                LabeledContent("Importquelle") {
                    Label(proposition.importSource.displayName, systemImage: proposition.importSource.icon)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Proposition löschen", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Proposition")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func iconForSubject(_ subject: String) -> String {
        // Temporäre Proposition zum Abfragen des Icons
        let temp = Proposition(keyMessage: "", subject: subject)
        return temp.subjectIcon
    }
}
