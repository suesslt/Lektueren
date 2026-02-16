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
            PDFFolder.self,
            PDFItem.self,
        ])
        // CloudKit-Sync: cloudKitDatabase auf .automatic setzen.
        // Voraussetzung: CloudKit-Capability im Xcode-Target aktiviert
        // und ein iCloud-Container z. B. "iCloud.com.yourcompany.GenericTreeModel" eingetragen.
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            // PDFTreeDataProvider liest Folder + Items per @Query,
            // aktualisiert den ViewModel und gibt ihn an den Layout-View weiter.
            PDFTreeDataProvider { viewModel in
                TripleColumnLayout(viewModel: viewModel) { item in
                    PDFDetailView(item: item)
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
