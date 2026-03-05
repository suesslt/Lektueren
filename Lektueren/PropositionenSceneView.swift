//
//  PropositionenSceneView.swift
//  Lektüren
//
//  Scene für Propositionen und Erkenntnisberichte.
//  NavigationSplitView mit Kategorie-/Berichts-Sidebar, Listen und Detail.
//

import SwiftUI

// MARK: - Sub-Section

enum PropositionSubSection: String, Hashable, CaseIterable {
    case propositionen = "Propositionen"
    case erkenntnisberichte = "Erkenntnisberichte"

    var icon: String {
        switch self {
        case .propositionen: return "text.quote"
        case .erkenntnisberichte: return "doc.text.magnifyingglass"
        }
    }
}

// MARK: - PropositionenSceneView

struct PropositionenSceneView: View {
    var propositionViewModel: PropositionViewModel
    var findingsReportViewModel: FindingsReportViewModel
    var cleanupViewModel: PropositionCleanupViewModel
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showingSettings = false
    @State private var showingCleanup = false
    @State private var selectedSubSection: PropositionSubSection = .propositionen

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
                .navigationTitle("Propositionen")
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showingCleanup = true
                        } label: {
                            Label("Bereinigung", systemImage: "wand.and.stars")
                        }
                    }
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Einstellungen", systemImage: "gear")
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
                .sheet(isPresented: $showingCleanup) {
                    PropositionCleanupView(viewModel: cleanupViewModel)
                }
        } content: {
            contentColumn
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.prominentDetail)
        .onAppear {
            columnVisibility = .all
        }
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebarContent: some View {
        List {
            Section("Ansicht") {
                ForEach(PropositionSubSection.allCases, id: \.self) { section in
                    subSectionButton(for: section)
                }
            }

            switch selectedSubSection {
            case .propositionen:
                propositionCategorySection
            case .erkenntnisberichte:
                findingsReportSidebarSection
            }
        }
    }

    private func subSectionButton(for section: PropositionSubSection) -> some View {
        let isSelected = selectedSubSection == section
        return Button {
            selectedSubSection = section
        } label: {
            Label(section.rawValue, systemImage: section.icon)
        }
        .foregroundStyle(isSelected ? .primary : .secondary)
        .listRowBackground(
            isSelected ? Color.accentColor.opacity(0.15) : Color.clear
        )
    }

    // MARK: - Proposition Category Section

    @ViewBuilder
    private var propositionCategorySection: some View {
        Section("Kategorien") {
            let isAllSelected = propositionViewModel.selectedCategory == nil
            Button {
                propositionViewModel.selectedCategory = nil
            } label: {
                HStack {
                    Label("Alle", systemImage: "tray.full")
                    Spacer()
                    Text("\(propositionViewModel.totalCount)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .foregroundStyle(isAllSelected ? .primary : .secondary)
            .listRowBackground(
                isAllSelected ? Color.accentColor.opacity(0.15) : Color.clear
            )

            let counts = propositionViewModel.categoryCounts
            ForEach(propositionViewModel.activeCategories, id: \.self) { category in
                let isSelected = propositionViewModel.selectedCategory == category
                Button {
                    propositionViewModel.selectedCategory = category
                } label: {
                    HStack {
                        Label(category, systemImage: iconForCategory(category))
                            .foregroundStyle(colorForCategory(category))
                        Spacer()
                        Text("\(counts[category, default: 0])")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .listRowBackground(
                    isSelected ? Color.accentColor.opacity(0.15) : Color.clear
                )
            }
        }
    }

    // MARK: - Findings Report Sidebar Section

    @ViewBuilder
    private var findingsReportSidebarSection: some View {
        Section("Berichte") {
            HStack {
                Label("Alle Berichte", systemImage: "tray.full")
                Spacer()
                Text("\(findingsReportViewModel.totalCount)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .foregroundStyle(.primary)
            .listRowBackground(Color.accentColor.opacity(0.15))
        }
    }

    // MARK: - Content Column

    @ViewBuilder
    private var contentColumn: some View {
        switch selectedSubSection {
        case .propositionen:
            PropositionListView(viewModel: propositionViewModel)
        case .erkenntnisberichte:
            FindingsReportListView(viewModel: findingsReportViewModel)
        }
    }

    // MARK: - Detail Column

    @ViewBuilder
    private var detailColumn: some View {
        switch selectedSubSection {
        case .propositionen:
            if let proposition = propositionViewModel.selectedProposition {
                PropositionDetailView(
                    proposition: proposition,
                    onSave: { propositionViewModel.save() },
                    onDelete: { propositionViewModel.deleteProposition(proposition) }
                )
            } else {
                Text("Bitte wählen Sie eine Proposition aus.")
            }
        case .erkenntnisberichte:
            if let report = findingsReportViewModel.selectedReport {
                FindingsReportDetailView(
                    report: report,
                    onDelete: { findingsReportViewModel.deleteReport(report) }
                )
            } else {
                Text("Bitte wählen Sie einen Erkenntnisbericht aus.")
            }
        }
    }

    // MARK: - Category Helpers

    private func iconForCategory(_ category: String) -> String {
        let temp = Proposition(keyMessage: "", subject: category)
        return temp.subjectIcon
    }

    private func colorForCategory(_ category: String) -> Color {
        let temp = Proposition(keyMessage: "", subject: category)
        return temp.subjectColor
    }
}
