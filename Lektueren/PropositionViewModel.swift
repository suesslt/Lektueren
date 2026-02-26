//
//  PropositionViewModel.swift
//  Lektüren
//
//  ViewModel für Propositionen: CRUD, Suche, Kategorie-Filter, CSV- und Notes-Import.
//

import SwiftUI
import SwiftData

@Observable
@MainActor
class PropositionViewModel {

    var searchText: String = ""
    var selectedCategory: String?
    var selectedProposition: Proposition?

    /// Fortschritts-Tracking für Notes-Import
    var isImporting: Bool = false
    var importProgress: String = ""

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Computed Properties

    var displayedPropositions: [Proposition] {
        let descriptor = FetchDescriptor<Proposition>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allProps = (try? modelContext.fetch(descriptor)) ?? []

        var filtered = allProps

        // Kategorie-Filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.subject == category }
        }

        // Textsuche nur auf keyMessage
        if !searchText.isEmpty {
            let search = searchText.lowercased()
            filtered = filtered.filter { $0.keyMessage.lowercased().contains(search) }
        }

        return filtered
    }

    var totalCount: Int {
        (try? modelContext.fetchCount(FetchDescriptor<Proposition>())) ?? 0
    }

    /// Zählt Propositionen pro Kategorie für die Sidebar-Anzeige.
    var categoryCounts: [String: Int] {
        let all = (try? modelContext.fetch(FetchDescriptor<Proposition>())) ?? []
        var counts: [String: Int] = [:]
        for p in all {
            counts[p.subject, default: 0] += 1
        }
        return counts
    }

    /// Nur Kategorien die tatsächlich Propositionen haben, sortiert.
    var activeCategories: [String] {
        let counts = categoryCounts
        return Proposition.allSubjects.filter { counts[$0, default: 0] > 0 }
    }

    // MARK: - CRUD

    func addProposition(keyMessage: String, subject: String, dateOfProposition: Date? = nil, source: String = "", noteTitle: String = "") {
        let prop = Proposition(
            keyMessage: keyMessage,
            subject: subject,
            dateOfProposition: dateOfProposition,
            source: source,
            noteTitle: noteTitle
        )
        modelContext.insert(prop)
        try? modelContext.save()
    }

    func deleteProposition(_ proposition: Proposition) {
        if selectedProposition?.id == proposition.id {
            selectedProposition = nil
        }
        modelContext.delete(proposition)
        try? modelContext.save()
    }

    func deleteAll() {
        selectedProposition = nil
        try? modelContext.delete(model: Proposition.self)
        try? modelContext.save()
    }

    func save() {
        try? modelContext.save()
    }

    // MARK: - CSV Export

    func exportCSV() -> String {
        let all = (try? modelContext.fetch(
            FetchDescriptor<Proposition>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        )) ?? []
        return CSVService.exportCSV(from: all)
    }

    // MARK: - CSV Import

    func importCSV(from url: URL) async {
        guard url.startAccessingSecurityScopedResource() else {
            importProgress = "Zugriff auf CSV-Datei fehlgeschlagen."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        isImporting = true
        importProgress = "Lese CSV-Datei..."

        do {
            let csvString = try String(contentsOf: url, encoding: .utf8)
            importProgress = "Parse CSV-Daten..."
            await Task.yield()

            let imported = try CSVService.importCSV(csvString)
            let total = imported.count
            let batchSize = 50

            importProgress = "Importiere 0/\(total) Propositionen..."

            for (index, item) in imported.enumerated() {
                let prop = Proposition(
                    keyMessage: item.keyMessage,
                    subject: item.subject,
                    dateOfProposition: item.dateOfProposition,
                    source: item.source,
                    noteTitle: item.noteTitle
                )
                modelContext.insert(prop)

                // Batch-Save und UI-Update
                if (index + 1) % batchSize == 0 || index == total - 1 {
                    try? modelContext.save()
                    importProgress = "Importiere \(index + 1)/\(total) Propositionen..."
                    await Task.yield()
                }
            }

            importProgress = "\(total) Propositionen importiert."
            print("📥 [CSV] \(total) Propositionen importiert")
        } catch {
            importProgress = "Fehler: \(error.localizedDescription)"
            print("❌ [CSV Import] \(error.localizedDescription)")
        }

        isImporting = false
    }

    // MARK: - Notes Import (Markdown → Claude → Propositionen)

    func importFromNotes(folderURL: URL) async {
        guard folderURL.startAccessingSecurityScopedResource() else {
            importProgress = "Zugriff auf Ordner fehlgeschlagen."
            return
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        isImporting = true
        importProgress = "Lese Markdown-Dateien..."

        do {
            let notes = try NotesService.shared.readMarkdownNotes(from: folderURL)
            let apiKey = UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""

            guard !apiKey.isEmpty else {
                importProgress = "Kein API-Key konfiguriert."
                isImporting = false
                return
            }

            var totalExtracted = 0

            for (index, note) in notes.enumerated() {
                importProgress = "Verarbeite \(index + 1)/\(notes.count): \(note.title)..."

                do {
                    let propositions = try await ClaudeService.shared.extractPropositions(
                        from: note.body,
                        apiKey: apiKey
                    )

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")

                    for cp in propositions {
                        let dateOfProp = cp.zeitpunkt.flatMap { dateFormatter.date(from: $0) }
                        let prop = Proposition(
                            keyMessage: cp.kernaussage,
                            subject: cp.subjekt,
                            dateOfProposition: dateOfProp,
                            source: cp.quelle ?? "",
                            noteTitle: note.title,
                            importSource: .appleNotes
                        )
                        modelContext.insert(prop)
                        totalExtracted += 1
                    }
                    try? modelContext.save()
                } catch {
                    print("⚠️ [Notes Import] Fehler bei '\(note.title)': \(error.localizedDescription)")
                }

                // UI-Thread freigeben
                await Task.yield()
            }

            importProgress = "\(totalExtracted) Propositionen aus \(notes.count) Notizen extrahiert."
            print("✅ [Notes Import] \(totalExtracted) Propositionen aus \(notes.count) Notizen")
        } catch {
            importProgress = "Fehler: \(error.localizedDescription)"
            print("❌ [Notes Import] \(error.localizedDescription)")
        }

        isImporting = false
    }
}
