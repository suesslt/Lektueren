//
//  PropositionCleanupView.swift
//  Lektüren
//
//  UI für die KI-gestützte Bereinigung von Propositionen.
//  Zeigt Analyse-Fortschritt, Ergebnisse und ermöglicht Überprüfung vor dem Löschen.
//

import SwiftUI

struct PropositionCleanupView: View {
    var viewModel: PropositionCleanupViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Bereinigung")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Schliessen") { dismiss() }
                    }
                    if viewModel.analysisComplete && !viewModel.cleanupItems.isEmpty {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Löschen (\(viewModel.selectedForDeletion.count))") {
                                showDeleteConfirmation = true
                            }
                            .disabled(viewModel.selectedForDeletion.isEmpty)
                            .foregroundStyle(.red)
                        }
                    }
                }
                .confirmationDialog(
                    "Propositionen löschen",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("\(viewModel.selectedForDeletion.count) Propositionen löschen", role: .destructive) {
                        viewModel.deleteSelected()
                    }
                    Button("Abbrechen", role: .cancel) {}
                } message: {
                    Text("Diese Aktion kann nicht rückgängig gemacht werden.")
                }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isAnalyzing {
            analysisProgressView
        } else if viewModel.analysisComplete {
            if viewModel.cleanupItems.isEmpty {
                ContentUnavailableView(
                    "Keine Probleme gefunden",
                    systemImage: "checkmark.circle",
                    description: Text("Alle Propositionen sind einzigartig und qualitativ hochwertig.")
                )
            } else {
                resultsList
            }
        } else {
            startView
        }
    }

    // MARK: - Start

    private var startView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 60))
                .foregroundStyle(.teal)

            Text("KI-gestützte Bereinigung")
                .font(.title2.bold())

            Text("Analysiert alle Propositionen auf semantische Duplikate und Qualitätsprobleme. Die Ergebnisse werden zur Überprüfung angezeigt — nichts wird automatisch gelöscht.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)

            if let error = viewModel.analysisError {
                Text(error)
                    .foregroundStyle(.red)
                    .padding()
            }

            Button {
                Task { await viewModel.startAnalysis() }
            } label: {
                Label("Analyse starten", systemImage: "play.fill")
                    .font(.headline)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
        }
        .padding()
    }

    // MARK: - Progress

    private var analysisProgressView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text(viewModel.progress)
                .font(.headline)

            Text(viewModel.progressDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.totalBatches > 0 {
                ProgressView(value: Double(viewModel.processedBatches), total: Double(viewModel.totalBatches))
                    .padding(.horizontal, 40)

                Text("\(viewModel.processedBatches)/\(viewModel.totalBatches)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.cleanupItems.isEmpty {
                Text("\(viewModel.cleanupItems.count) Vorschläge bisher")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Abbrechen", role: .destructive) {
                viewModel.cancelAnalysis()
            }
            .padding(.top)
        }
        .padding()
    }

    // MARK: - Results

    private var resultsList: some View {
        VStack(spacing: 0) {
            summaryBar
            List {
                let duplicates = viewModel.cleanupItems.filter { $0.type == .duplicate }
                let lowQuality = viewModel.cleanupItems.filter { $0.type == .lowQuality }

                if !duplicates.isEmpty {
                    Section("Duplikate (\(duplicates.count))") {
                        ForEach(duplicates) { item in
                            cleanupRow(item)
                        }
                    }
                }

                if !lowQuality.isEmpty {
                    Section("Qualitätsprobleme (\(lowQuality.count))") {
                        ForEach(lowQuality) { item in
                            cleanupRow(item)
                        }
                    }
                }
            }
        }
    }

    private var summaryBar: some View {
        HStack {
            Label("\(viewModel.totalDuplicates) Duplikate", systemImage: "doc.on.doc")
            Spacer()
            Label("\(viewModel.totalLowQuality) Qualität", systemImage: "exclamationmark.triangle")
            Spacer()
            Button("Alle") { viewModel.selectAll() }
                .font(.caption.bold())
            Button("Keine") { viewModel.deselectAll() }
                .font(.caption.bold())
        }
        .font(.caption)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func cleanupRow(_ item: PropositionCleanupItem) -> some View {
        let isSelected = viewModel.selectedForDeletion.contains(item.id)
        return Button {
            viewModel.toggleSelection(item.id)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .red : .secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.keyMessage)
                        .font(.body)
                        .lineLimit(3)
                        .foregroundStyle(.primary)

                    Text(item.subject)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.12), in: Capsule())

                    Text(item.reason)
                        .font(.caption)
                        .foregroundStyle(.orange)

                    if let keepMsg = item.keepKeyMessage {
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                            Text("Behalten: \(keepMsg)")
                        }
                        .font(.caption)
                        .foregroundStyle(.green)
                        .lineLimit(2)
                    }
                }
            }
        }
        .listRowBackground(
            isSelected ? Color.red.opacity(0.05) : Color.clear
        )
    }
}
