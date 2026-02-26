//
//  FindingsReportListView.swift
//  Lektüren
//
//  Mittlere Spalte (Content) für die Erkenntnisberichte-Ansicht.
//  Zeigt eine Liste aller Berichte mit Generierung und Verwaltung.
//

import SwiftUI

struct FindingsReportListView: View {
    @Bindable var viewModel: FindingsReportViewModel
    @State private var isShowingTopicDialog = false
    @State private var topicInput = ""
    @State private var isConfirmingDeleteAll = false

    var body: some View {
        contentView
            .navigationTitle("Erkenntnisberichte")
            .toolbar { toolbarContent }
            .alert("Neuer Erkenntnisbericht", isPresented: $isShowingTopicDialog) {
                TextField("z.B. Sicherheitspolitik Schweiz", text: $topicInput)
                Button("Erstellen") {
                    let trimmed = topicInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    Task { await viewModel.generateReport(topic: trimmed) }
                    topicInput = ""
                }
                Button("Abbrechen", role: .cancel) { topicInput = "" }
            } message: {
                Text("Geben Sie ein Thema ein. Alle Propositionen werden analysiert und zu einem Erkenntnisbericht zusammengeführt.")
            }
            .confirmationDialog(
                "Alle Berichte löschen?",
                isPresented: $isConfirmingDeleteAll,
                titleVisibility: .visible
            ) {
                Button("Alle Berichte löschen", role: .destructive) {
                    viewModel.deleteAll()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Dieser Vorgang löscht alle Erkenntnisberichte unwiderruflich.")
            }
            .alert("Fehler", isPresented: showError) {
                Button("OK") { viewModel.generationError = nil }
            } message: {
                Text(viewModel.generationError ?? "")
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isGenerating {
            generatingView
        } else {
            let reports = viewModel.allReports
            if !reports.isEmpty {
                reportList(reports)
            } else {
                emptyView
            }
        }
    }

    private func reportList(_ reports: [FindingsReport]) -> some View {
        List(selection: Binding(
            get: { viewModel.selectedReport?.id },
            set: { newID in
                viewModel.selectedReport = newID.flatMap { id in
                    reports.first { $0.id == id }
                }
            }
        )) {
            ForEach(reports) { report in
                FindingsReportRowView(report: report)
                    .tag(report.id)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteReport(report)
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
            }
        }
    }

    private var generatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(viewModel.generationProgress)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Dies kann einige Sekunden dauern...")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "Keine Erkenntnisberichte",
            systemImage: "doc.text.magnifyingglass",
            description: Text("Erstelle einen Erkenntnisbericht aus deinen Propositionen über das Menu oben.")
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    isShowingTopicDialog = true
                } label: {
                    Label("Neuer Erkenntnisbericht", systemImage: "doc.text.magnifyingglass")
                }
                .disabled(viewModel.isGenerating)

                Divider()

                Button(role: .destructive) {
                    isConfirmingDeleteAll = true
                } label: {
                    Label("Alle löschen", systemImage: "trash")
                }
                .disabled(viewModel.totalCount == 0)
            } label: {
                Label("Aktionen", systemImage: "ellipsis.circle")
            }
        }
    }

    // MARK: - Helpers

    private var showError: Binding<Bool> {
        Binding(
            get: { viewModel.generationError != nil },
            set: { if !$0 { viewModel.generationError = nil } }
        )
    }
}
