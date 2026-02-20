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
            PDFRootView(modelContext: sharedModelContainer.mainContext)
        }
        .modelContainer(sharedModelContainer)
    }

    init() {
        // Gibt beim App-Start Diagnoseinformationen zur iCloud-Anbindung aus.
        // Prüfe die Xcode-Konsole auf "[PDFCloudStorage]"-Zeilen.
        PDFCloudStorage.logDiagnostics()
    }
}
/// Einstiegspunkt, der den ViewModel mit dem MainContext initialisiert.
private struct PDFRootView: View {
    @State private var viewModel: PDFTreeViewModel

    init(modelContext: ModelContext) {
        _viewModel = State(wrappedValue: PDFTreeViewModel(modelContext: modelContext))
    }

    var body: some View {
        TripleColumnLayout(viewModel: viewModel) { item in
            PDFDetailView(item: item)
        }
    }
}

