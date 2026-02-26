//
//  AppRootView.swift
//  Lektüren
//
//  Haupt-View mit TabView für die zwei Szenen:
//  - Lektüren (PDFs)
//  - Propositionen (inkl. Erkenntnisberichte)
//

import SwiftUI
import SwiftData

// MARK: - AppRootView

struct AppRootView: View {
    @State private var pdfViewModel: PDFTreeViewModel
    @State private var propositionViewModel: PropositionViewModel
    @State private var findingsReportViewModel: FindingsReportViewModel

    init(modelContext: ModelContext) {
        _pdfViewModel = State(wrappedValue: PDFTreeViewModel(modelContext: modelContext))
        _propositionViewModel = State(wrappedValue: PropositionViewModel(modelContext: modelContext))
        _findingsReportViewModel = State(wrappedValue: FindingsReportViewModel(modelContext: modelContext))
    }

    var body: some View {
        TabView {
            LektuerenSceneView(viewModel: pdfViewModel)
                .tabItem {
                    Label("Lektüren", systemImage: "books.vertical")
                }

            PropositionenSceneView(
                propositionViewModel: propositionViewModel,
                findingsReportViewModel: findingsReportViewModel
            )
                .tabItem {
                    Label("Propositionen", systemImage: "text.quote")
                }
        }
    }
}
