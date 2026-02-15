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
            TripleColumnLayout(viewModel: PDFTreeViewModel()) { item in
                PDFDetailView(item: item)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
