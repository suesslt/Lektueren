//
//  PDFManagerApp.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI
import SwiftData

@main
struct PDFManagerApp: App {
  
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PDFItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TripleColumnLayout(viewModel: PDFTreeViewModel())
        }
        .modelContainer(sharedModelContainer)
    }
}

// Ergänzung zum vorherigen TripleColumnLayout für die Detail-Spalte:
// detail: {
//    if let item = viewModel.selectedDetailItem {
//        GenericDetailView(item: item)
//    } else {
//        ContentUnavailableView("Keine Auswahl", systemImage: "pdf")
//    }
// }
