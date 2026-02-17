//
//  PDFCloudStorage.swift
//  Lektüren
//
//  Verwaltet das Kopieren von PDF-Dateien in den App-spezifischen
//  iCloud-Drive-Container, damit sie geräteübergreifend verfügbar sind.
//
import Foundation

enum PDFCloudStorageError: Error, LocalizedError {
    case iCloudNotAvailable
    case copyFailed(underlying: Error)
    case downloadFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud ist auf diesem Gerät nicht verfügbar oder nicht angemeldet."
        case .copyFailed(let error):
            return "Die Datei konnte nicht in iCloud kopiert werden: \(error.localizedDescription)"
        case .downloadFailed(let error):
            return "Die Datei konnte nicht aus iCloud geladen werden: \(error.localizedDescription)"
        }
    }
}

/// Zuständig für das Verwalten von PDF-Dateien im App-spezifischen iCloud-Container.
///
/// Voraussetzungen im Xcode-Target:
/// - iCloud-Capability aktiviert
/// - „iCloud Documents" aktiviert (nicht nur CloudKit)
/// - Container-ID z. B. „iCloud.com.yourcompany.GenericTreeModel" eingetragen
/// - Info.plist: `NSUbiquitousContainers` mit entsprechendem Eintrag
struct PDFCloudStorage {

    // MARK: - Container-Konfiguration

    /// Die Container-ID muss mit dem Eintrag in der iCloud-Capability übereinstimmen.
    /// Setze hier deinen eigentlichen Bundle-Identifier ein.
    private static let containerIdentifier: String? = nil // nil = Standard-Container des App-Bundles

    /// Unterordner im iCloud-Container, in dem alle PDFs abgelegt werden.
    private static let pdfSubdirectory = "PDFs"

    // MARK: - Öffentliche Schnittstelle

    /// Gibt die URL des iCloud-PDF-Verzeichnisses zurück.
    /// Erstellt das Verzeichnis, falls es noch nicht existiert.
    /// - Throws: `PDFCloudStorageError.iCloudNotAvailable` falls iCloud nicht eingerichtet ist.
    static func cloudPDFDirectory() throws -> URL {
        guard let containerURL = FileManager.default.url(
            forUbiquityContainerIdentifier: containerIdentifier
        ) else {
            throw PDFCloudStorageError.iCloudNotAvailable
        }

        // iCloud Drive legt Dateien im Unterordner „Documents" ab.
        let documentsURL = containerURL.appendingPathComponent("Documents", isDirectory: true)
        let pdfDirectoryURL = documentsURL.appendingPathComponent(pdfSubdirectory, isDirectory: true)

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

        // Kollisionsvermeidung: Falls der Dateiname bereits existiert,
        // wird ein UUID-Präfix vorangestellt.
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
    ///
    /// Fehler beim Löschen werden ignoriert (z. B. Datei bereits nicht vorhanden).
    /// - Parameter cloudURL: Die URL der Datei im iCloud-Container.
    static func removeFromCloud(at cloudURL: URL) {
        guard isCloudURL(cloudURL) else { return }
        try? FileManager.default.removeItem(at: cloudURL)
    }

    /// Startet den iCloud-Download einer Datei, falls sie noch nicht lokal verfügbar ist.
    ///
    /// - Parameter cloudURL: Die URL der Datei im iCloud-Container.
    /// - Throws: `PDFCloudStorageError.downloadFailed`
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
