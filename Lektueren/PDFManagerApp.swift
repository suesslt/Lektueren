//
//  PDFManagerApp.swift
//  Lektüren
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
            Proposition.self,
            FindingsReport.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
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
            AppRootView(modelContext: sharedModelContainer.mainContext)
        }
        .modelContainer(sharedModelContainer)
    }

    init() {
        // Gibt beim App-Start Diagnoseinformationen zur iCloud-Anbindung aus.
        // Prüfe die Xcode-Konsole auf "[PDFCloudStorage]"-Zeilen.
        PDFCloudStorage.logDiagnostics()
    }
}

