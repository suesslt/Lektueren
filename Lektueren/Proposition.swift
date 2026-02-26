//
//  Proposition.swift
//  Propositions
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Import Source

/// Quelle, aus der eine Proposition importiert wurde.
/// Ermöglicht zukünftige Erweiterungen (z.B. Webseiten, Kindle-Markierungen).
enum ImportSource: String, Codable, CaseIterable {
    case appleNotes = "appleNotes"
    case pdf = "pdf"
    case manual = "manual"

    var displayName: String {
        switch self {
        case .appleNotes: return "Apple Notizen"
        case .pdf: return "PDF"
        case .manual: return "Manuell"
        }
    }

    var icon: String {
        switch self {
        case .appleNotes: return "note.text"
        case .pdf: return "doc.richtext"
        case .manual: return "pencil"
        }
    }
}

// MARK: - Proposition Model

@Model
final class Proposition {
    var id: UUID = UUID()
    var keyMessage: String = ""
    var subject: String = ""
    var dateOfProposition: Date?
    var source: String = ""
    var noteTitle: String = ""
    var createdAt: Date = Date()

    /// Importquelle als Raw-Value gespeichert (SwiftData-Kompatibilität).
    var importSourceRaw: String = ImportSource.manual.rawValue

    /// Optionale Beziehung zum PDF, aus dem diese Proposition extrahiert wurde.
    var pdfItem: PDFItem?

    /// Typisierter Zugriff auf die Importquelle.
    @Transient
    var importSource: ImportSource {
        get { ImportSource(rawValue: importSourceRaw) ?? .manual }
        set { importSourceRaw = newValue.rawValue }
    }

    init(keyMessage: String, subject: String, dateOfProposition: Date? = nil, source: String = "", noteTitle: String = "", pdfItem: PDFItem? = nil, importSource: ImportSource = .manual) {
        self.id = UUID()
        self.keyMessage = keyMessage
        self.subject = subject
        self.dateOfProposition = dateOfProposition
        self.source = source
        self.noteTitle = noteTitle
        self.createdAt = Date()
        self.importSourceRaw = importSource.rawValue
        self.pdfItem = pdfItem
    }

    static let allSubjects: [String] = [
        "Geopolitik - Russland",
        "Geopolitik - China",
        "Geopolitik - USA",
        "Künstliche Intelligenz",
        "Schweizer Wirtschaft",
        "Innovation und Disruption",
        "Schweizer Geschichte",
        "Cyber",
        "Militär und Rüstung",
        "Schweizer Politik",
        "Europa und EU",
        "Energieversorgung Schweiz",
        "Staatsfinanzen Schweiz",
        "Zeitenwende",
        "Demographie und Gesellschaft",
        "Klimawandel",
        "Leadership",
        "Sicherheit Schweiz"
    ]

    var subjectColor: Color {
        switch subject {
        case "Geopolitik - Russland": return .red
        case "Geopolitik - China": return .orange
        case "Geopolitik - USA": return .blue
        case "Künstliche Intelligenz": return .purple
        case "Schweizer Wirtschaft": return .green
        case "Innovation und Disruption": return .cyan
        case "Schweizer Geschichte": return .brown
        case "Cyber": return .indigo
        case "Militär und Rüstung": return .gray
        case "Schweizer Politik": return Color(red: 0.8, green: 0.2, blue: 0.2)
        case "Europa und EU": return Color(red: 0.2, green: 0.3, blue: 0.8)
        case "Energieversorgung Schweiz": return .yellow
        case "Staatsfinanzen Schweiz": return .mint
        case "Zeitenwende": return .pink
        case "Demographie und Gesellschaft": return .teal
        case "Klimawandel": return Color(red: 0.2, green: 0.6, blue: 0.3)
        case "Leadership": return Color(red: 0.9, green: 0.5, blue: 0.1)
        case "Sicherheit Schweiz": return Color(red: 0.7, green: 0.1, blue: 0.1)
        default: return .secondary
        }
    }

    var subjectIcon: String {
        switch subject {
        case "Geopolitik - Russland": return "globe.europe.africa"
        case "Geopolitik - China": return "globe.asia.australia"
        case "Geopolitik - USA": return "globe.americas"
        case "Künstliche Intelligenz": return "brain"
        case "Schweizer Wirtschaft": return "chart.line.uptrend.xyaxis"
        case "Innovation und Disruption": return "lightbulb"
        case "Schweizer Geschichte": return "book"
        case "Cyber": return "lock.shield"
        case "Militär und Rüstung": return "shield.checkered"
        case "Schweizer Politik": return "building.columns"
        case "Europa und EU": return "flag"
        case "Energieversorgung Schweiz": return "bolt"
        case "Staatsfinanzen Schweiz": return "banknote"
        case "Zeitenwende": return "clock.arrow.circlepath"
        case "Demographie und Gesellschaft": return "person.3"
        case "Klimawandel": return "thermometer.sun"
        case "Leadership": return "person.badge.shield.checkmark"
        case "Sicherheit Schweiz": return "shield"
        default: return "doc.text"
        }
    }
}
