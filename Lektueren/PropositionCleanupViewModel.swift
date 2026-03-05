//
//  PropositionCleanupViewModel.swift
//  Lektüren
//
//  ViewModel für die KI-gestützte Bereinigung von Propositionen:
//  Erkennung von semantischen Duplikaten und Qualitätsproblemen.
//

import SwiftUI
import SwiftData

@Observable
@MainActor
class PropositionCleanupViewModel {

    var isAnalyzing = false
    var progress: String = ""
    var progressDetail: String = ""
    var processedBatches: Int = 0
    var totalBatches: Int = 0

    var cleanupItems: [PropositionCleanupItem] = []
    var selectedForDeletion: Set<UUID> = []
    var analysisComplete = false
    var analysisError: String?

    var totalDuplicates: Int { cleanupItems.filter { $0.type == .duplicate }.count }
    var totalLowQuality: Int { cleanupItems.filter { $0.type == .lowQuality }.count }

    private let modelContext: ModelContext
    private var isCancelled = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Analyse

    func startAnalysis() async {
        isAnalyzing = true
        isCancelled = false
        cleanupItems = []
        selectedForDeletion = []
        analysisComplete = false
        analysisError = nil

        let apiKey = UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""
        guard !apiKey.isEmpty else {
            analysisError = "Kein API-Key konfiguriert. Bitte in den Einstellungen hinterlegen."
            isAnalyzing = false
            return
        }

        let descriptor = FetchDescriptor<Proposition>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allProps = (try? modelContext.fetch(descriptor)) ?? []

        guard !allProps.isEmpty else {
            analysisError = "Keine Propositionen vorhanden."
            isAnalyzing = false
            return
        }

        let grouped = Dictionary(grouping: allProps, by: { $0.subject })
        let categories = grouped.keys.sorted()

        let batchSize = 100
        var totalBatchCount = 0
        for (_, props) in grouped {
            totalBatchCount += (props.count + batchSize - 1) / batchSize
        }
        totalBatches = totalBatchCount
        processedBatches = 0

        print("🧹 [Cleanup] Start: \(allProps.count) Propositionen in \(categories.count) Kategorien, \(totalBatchCount) Batches")

        for category in categories {
            guard !isCancelled else { break }

            let props = grouped[category] ?? []
            progress = "Analysiere: \(category)"

            for batchStart in stride(from: 0, to: props.count, by: batchSize) {
                guard !isCancelled else { break }

                let batchEnd = min(batchStart + batchSize, props.count)
                let batch = Array(props[batchStart..<batchEnd])

                progressDetail = "Batch \(processedBatches + 1)/\(totalBatches) (\(batch.count) Propositionen)"

                do {
                    let indexed = batch.enumerated().map { (index: $0.offset, keyMessage: $0.element.keyMessage) }
                    let result = try await ClaudeService.shared.analyzePropositionsForCleanup(
                        propositions: indexed,
                        category: category,
                        apiKey: apiKey
                    )

                    // Duplikate zuordnen
                    for group in result.duplicateGroups {
                        let keepMsg = group.keepIndex < batch.count ? batch[group.keepIndex].keyMessage : "?"
                        for removeIdx in group.removeIndices {
                            guard removeIdx < batch.count else { continue }
                            let prop = batch[removeIdx]
                            let item = PropositionCleanupItem(
                                id: prop.id,
                                keyMessage: prop.keyMessage,
                                subject: prop.subject,
                                reason: group.reason,
                                type: .duplicate,
                                keepKeyMessage: keepMsg
                            )
                            cleanupItems.append(item)
                            selectedForDeletion.insert(prop.id)
                        }
                    }

                    // Qualitätsprobleme zuordnen
                    for lq in result.lowQuality {
                        guard lq.index < batch.count else { continue }
                        let prop = batch[lq.index]
                        let item = PropositionCleanupItem(
                            id: prop.id,
                            keyMessage: prop.keyMessage,
                            subject: prop.subject,
                            reason: lq.reason,
                            type: .lowQuality,
                            keepKeyMessage: nil
                        )
                        cleanupItems.append(item)
                        selectedForDeletion.insert(prop.id)
                    }

                    print("🧹 [Cleanup] \(category) Batch fertig: +\(result.duplicateGroups.flatMap(\.removeIndices).count) Duplikate, +\(result.lowQuality.count) Qualität")
                } catch {
                    print("⚠️ [Cleanup] Fehler bei \(category) Batch \(processedBatches): \(error.localizedDescription)")
                }

                processedBatches += 1

                // Rate-Limiting
                try? await Task.sleep(for: .milliseconds(500))
            }
        }

        isAnalyzing = false
        analysisComplete = true
        progress = "Analyse abgeschlossen"
        progressDetail = "\(cleanupItems.count) Vorschläge (\(totalDuplicates) Duplikate, \(totalLowQuality) Qualität)"
        print("🧹 [Cleanup] Fertig: \(cleanupItems.count) Vorschläge")
    }

    func cancelAnalysis() {
        isCancelled = true
    }

    // MARK: - Selection

    func toggleSelection(_ id: UUID) {
        if selectedForDeletion.contains(id) {
            selectedForDeletion.remove(id)
        } else {
            selectedForDeletion.insert(id)
        }
    }

    func selectAll() {
        selectedForDeletion = Set(cleanupItems.map(\.id))
    }

    func deselectAll() {
        selectedForDeletion.removeAll()
    }

    // MARK: - Deletion

    func deleteSelected() {
        let descriptor = FetchDescriptor<Proposition>()
        let allProps = (try? modelContext.fetch(descriptor)) ?? []

        var deletedCount = 0
        for prop in allProps {
            if selectedForDeletion.contains(prop.id) {
                modelContext.delete(prop)
                deletedCount += 1
            }
        }
        try? modelContext.save()

        cleanupItems.removeAll { selectedForDeletion.contains($0.id) }
        selectedForDeletion.removeAll()

        progress = "\(deletedCount) Propositionen gelöscht"
        progressDetail = "\(cleanupItems.count) verbleibende Vorschläge"
        print("🗑️ [Cleanup] \(deletedCount) Propositionen gelöscht")
    }

    // MARK: - Reset

    func reset() {
        cleanupItems = []
        selectedForDeletion = []
        analysisComplete = false
        analysisError = nil
        progress = ""
        progressDetail = ""
        processedBatches = 0
        totalBatches = 0
    }
}
