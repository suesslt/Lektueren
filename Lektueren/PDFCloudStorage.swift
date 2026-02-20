//
//  PDFCloudStorage.swift
//  Lektüren
//
//  Verwaltet das Kopieren von PDF-Dateien in den iCloud-Drive-Container,
//  damit sie geräteübergreifend verfügbar sind und direkt neben Numbers,
//  Keynote etc. im iCloud Drive-Root erscheinen.
//
//  VORAUSSETZUNGEN (müssen alle erfüllt sein):
//  ─────────────────────────────────────────
//  1. Xcode → Target → Signing & Capabilities:
//       • iCloud Capability hinzufügen
//       • "CloudKit" angehakt          → synchronisiert SwiftData-Metadaten
//       • "iCloud Documents" angehakt  → synchronisiert PDF-Dateien
//       • Container: iCloud.com.suessli.Lektueren
//
//  2. Apple Developer Portal → Identifiers → deine App-ID:
//       • iCloud aktiviert
//       • Container "iCloud.com.suessli.Lektueren" erstellt UND verknüpft
//
//  3. Info.plist muss den NSUbiquitousContainers-Eintrag enthalten:
//       <key>NSUbiquitousContainers</key>
//       <dict>
//           <key>iCloud.com.suessli.Lektueren</key>
//           <dict>
//               <key>NSUbiquitousContainerIsDocumentScopePublic</key>
//               <true/>
//               <key>NSUbiquitousContainerName</key>
//               <string>Lektüren</string>
//               <key>NSUbiquitousContainerSupportedFolderLevels</key>
//               <string>Any</string>
//           </dict>
//       </dict>
//
//  WICHTIG: Durch Speicherung direkt im "Documents"-Ordner des Containers
//  erscheint der Ordner "Lektüren" im iCloud Drive-Root (wie Numbers, Keynote).
//
import Foundation

// MARK: - Errors

enum PDFCloudStorageError: Error, LocalizedError {
    case iCloudNotAvailable
    case containerNotFound(identifier: String)
    case copyFailed(underlying: Error)
    case downloadFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud ist auf diesem Gerät nicht verfügbar oder nicht angemeldet."
        case .containerNotFound(let id):
            return """
                Der iCloud-Container „\(id)" wurde nicht gefunden.
                Prüfe: Xcode Capabilities → iCloud Documents, \
                Developer Portal → iCloud Containers und den \
                NSUbiquitousContainers-Eintrag in der Info.plist.
                """
        case .copyFailed(let error):
            return "Die Datei konnte nicht in iCloud kopiert werden: \(error.localizedDescription)"
        case .downloadFailed(let error):
            return "Die Datei konnte nicht aus iCloud geladen werden: \(error.localizedDescription)"
        }
    }
}

// MARK: - Diagnostic Status

/// Beschreibt den aktuellen Verbindungsstatus zum iCloud-Container.
enum PDFCloudStatus: CustomStringConvertible {
    /// iCloud ist nicht angemeldet oder deaktiviert.
    case iCloudUnavailable
    /// iCloud ist verfügbar, aber der Container wurde nicht gefunden.
    /// Ursache: fehlende Capability, falscher Container-Name oder fehlender Info.plist-Eintrag.
    case containerNotFound
    /// Container gefunden, das Documents-Verzeichnis existiert noch nicht.
    case containerFoundNoDirectory
    /// Alles konfiguriert und bereit.
    case ready(directoryURL: URL)

    var description: String {
        switch self {
        case .iCloudUnavailable:       return "⛔ iCloud nicht verfügbar"
        case .containerNotFound:       return "⛔ Container nicht gefunden (Capability / Portal / Info.plist prüfen)"
        case .containerFoundNoDirectory: return "⚠️ Container OK, Verzeichnis wird erstellt"
        case .ready(let url):          return "✅ Bereit – \(url.path)"
        }
    }

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }
}

// MARK: - Storage

/// Zuständig für das Verwalten von PDF-Dateien im App-spezifischen iCloud-Container.
struct PDFCloudStorage {

    /// Die Container-ID muss exakt mit dem Eintrag in der iCloud-Capability
    /// und im Developer Portal übereinstimmen.
    /// Wichtig: Für sichtbare Ordner im iCloud Drive (wie Numbers, Keynote)
    /// muss die Container-ID mit "iCloud." + BundleIdentifier übereinstimmen.
    static let containerIdentifier = "iCloud.com.suessli.Lektueren"

    /// Name des Ordners, der direkt im iCloud Drive-Root erscheint.
    /// Dieser wird in der Dateien-App neben Numbers, Keynote etc. angezeigt.
    private static let appFolderName = "Lektüren"

    // MARK: - Diagnostics

    /// Prüft und liefert den aktuellen Verbindungsstatus – nützlich für Debugging und UI.
    ///
    /// Ruf diese Methode **nicht** auf dem Main-Thread auf, da
    /// `url(forUbiquityContainerIdentifier:)` blockieren kann.
    static func diagnose() -> PDFCloudStatus {
        // Schritt 1: Ist iCloud überhaupt verfügbar?
        guard FileManager.default.ubiquityIdentityToken != nil else {
            return .iCloudUnavailable
        }

        // Schritt 2: Ist der Container konfiguriert?
        guard let containerURL = FileManager.default.url(
            forUbiquityContainerIdentifier: containerIdentifier
        ) else {
            return .containerNotFound
        }

        // Schritt 3: Existiert das Zielverzeichnis bereits?
        // Verwende "Documents" für Sichtbarkeit im iCloud Drive-Root
        let directoryURL = containerURL
            .appendingPathComponent("Documents", isDirectory: true)

        guard FileManager.default.fileExists(atPath: directoryURL.path) else {
            return .containerFoundNoDirectory
        }

        return .ready(directoryURL: directoryURL)
    }

    /// Gibt Diagnoseinformationen in der Konsole aus.
    /// Hilfreich beim ersten Einrichten – in `PDFManagerApp.init()` aufrufen.
    static func logDiagnostics() {
        Task.detached(priority: .utility) {
            let status = diagnose()
            print("[PDFCloudStorage] Container: \(containerIdentifier)")
            print("[PDFCloudStorage] Status:    \(status)")
            if case .ready(let url) = status {
                let contents = (try? FileManager.default.contentsOfDirectory(atPath: url.path)) ?? []
                print("[PDFCloudStorage] Dateien im Container: \(contents.count)")
            }
        }
    }

    // MARK: - Öffentliche Schnittstelle

    /// Gibt die URL des iCloud-PDF-Verzeichnisses zurück.
    /// Erstellt das Verzeichnis, falls es noch nicht existiert.
    /// Die PDFs werden direkt im "Documents"-Ordner des iCloud-Containers gespeichert,
    /// was sie im iCloud Drive-Root sichtbar macht (wie Numbers, Keynote etc.).
    /// - Throws: `PDFCloudStorageError`
    static func cloudPDFDirectory() throws -> URL {
        guard FileManager.default.ubiquityIdentityToken != nil else {
            throw PDFCloudStorageError.iCloudNotAvailable
        }

        guard let containerURL = FileManager.default.url(
            forUbiquityContainerIdentifier: containerIdentifier
        ) else {
            throw PDFCloudStorageError.containerNotFound(identifier: containerIdentifier)
        }

        // Speichere direkt im "Documents"-Ordner, um im iCloud Drive-Root sichtbar zu sein
        let pdfDirectoryURL = containerURL
            .appendingPathComponent("Documents", isDirectory: true)

        try FileManager.default.createDirectory(
            at: pdfDirectoryURL,
            withIntermediateDirectories: true
        )
        return pdfDirectoryURL
    }

    /// Kopiert eine PDF-Datei vom lokalen Filesystem in den iCloud-Container.
    ///
    /// - Falls bereits eine Datei mit dem gleichen Namen existiert, wird diese
    ///   durch einen eindeutigen Dateinamen (UUID-Präfix) ergänzt.
    /// - Parameter sourceURL: Die ursprüngliche URL der PDF-Datei.
    /// - Returns: Die neue URL der Datei im iCloud-Container.
    /// - Throws: `PDFCloudStorageError`
    @discardableResult
    static func copyToCloud(from sourceURL: URL) throws -> URL {
        let directory = try cloudPDFDirectory()

        let originalName = sourceURL.lastPathComponent
        var destinationURL = directory.appendingPathComponent(originalName)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            let uniqueName = UUID().uuidString + "_" + originalName
            destinationURL = directory.appendingPathComponent(uniqueName)
        }

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw PDFCloudStorageError.copyFailed(underlying: error)
        }

        return destinationURL
    }

    /// Löscht eine PDF-Datei aus dem iCloud-Container.
    static func removeFromCloud(at cloudURL: URL) {
        guard isCloudURL(cloudURL) else { return }
        try? FileManager.default.removeItem(at: cloudURL)
    }

    /// Startet den iCloud-Download einer Datei, falls sie noch nicht lokal verfügbar ist.
    static func ensureDownloaded(at cloudURL: URL) throws {
        let resourceValues = try cloudURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
        if resourceValues.ubiquitousItemDownloadingStatus != .current {
            do {
                try FileManager.default.startDownloadingUbiquitousItem(at: cloudURL)
            } catch {
                throw PDFCloudStorageError.downloadFailed(underlying: error)
            }
        }
    }

    /// Gibt an, ob eine URL auf eine Datei im iCloud-Container zeigt.
    static func isCloudURL(_ url: URL) -> Bool {
        guard let containerURL = FileManager.default.url(
            forUbiquityContainerIdentifier: containerIdentifier
        ) else { return false }
        return url.path.hasPrefix(containerURL.path)
    }

    /// Prüft, ob iCloud auf diesem Gerät verfügbar ist.
    static var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
}
