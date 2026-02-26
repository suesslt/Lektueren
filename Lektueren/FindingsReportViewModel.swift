//
//  FindingsReportViewModel.swift
//  Lektüren
//
//  ViewModel für Erkenntnisberichte: Generierung, CRUD und Verwaltung.
//

import SwiftUI
import SwiftData

@Observable
@MainActor
class FindingsReportViewModel {

    var selectedReport: FindingsReport?
    var isGenerating: Bool = false
    var generationProgress: String = ""
    var generationError: String?

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Computed Properties

    var allReports: [FindingsReport] {
        let descriptor = FetchDescriptor<FindingsReport>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var totalCount: Int {
        (try? modelContext.fetchCount(FetchDescriptor<FindingsReport>())) ?? 0
    }

    // MARK: - Report-Generierung

    func generateReport(topic: String) async {
        isGenerating = true
        generationProgress = "Lade Propositionen..."
        generationError = nil

        let apiKey = UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""
        guard !apiKey.isEmpty else {
            generationError = "Kein API-Key konfiguriert. Bitte in den Einstellungen hinterlegen."
            isGenerating = false
            return
        }

        // 1. Alle Propositionen laden
        let descriptor = FetchDescriptor<Proposition>(
            sortBy: [SortDescriptor(\.subject)]
        )
        let allPropositions = (try? modelContext.fetch(descriptor)) ?? []

        guard !allPropositions.isEmpty else {
            generationError = "Keine Propositionen vorhanden. Importiere zuerst Propositionen."
            isGenerating = false
            return
        }

        generationProgress = "Sende \(allPropositions.count) Propositionen an Claude..."
        await Task.yield()

        do {
            // 2. Claude API aufrufen
            let markdown = try await ClaudeService.shared.generateFindingsReport(
                topic: topic,
                propositions: allPropositions,
                apiKey: apiKey
            )

            generationProgress = "Erstelle PDF aus Markdown..."
            await Task.yield()

            // 3. Markdown zu PDF konvertieren
            let pdfData = await MarkdownPDFRenderer.renderToPDF(markdown: markdown, topic: topic)

            // 4. FindingsReport erstellen und speichern
            let report = FindingsReport(
                topic: topic,
                markdownContent: markdown,
                pdfData: pdfData
            )
            modelContext.insert(report)
            try? modelContext.save()

            selectedReport = report
            generationProgress = "Erkenntnisbericht erstellt."
            print("✅ [Findings Report] Bericht '\(topic)' erstellt, PDF: \(pdfData != nil ? "ja" : "nein")")
        } catch {
            generationError = "Fehler: \(error.localizedDescription)"
            print("❌ [Findings Report] \(error.localizedDescription)")
        }

        isGenerating = false
    }

    // MARK: - CRUD

    func deleteReport(_ report: FindingsReport) {
        if selectedReport?.id == report.id {
            selectedReport = nil
        }
        modelContext.delete(report)
        try? modelContext.save()
    }

    func deleteAll() {
        selectedReport = nil
        try? modelContext.delete(model: FindingsReport.self)
        try? modelContext.save()
    }

    func save() {
        try? modelContext.save()
    }
}
