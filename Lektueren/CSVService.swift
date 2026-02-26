//
//  CSVService.swift
//  Propositions
//
//  CSV Export & Import for Propositions.
//  RFC 4180 compliant: fields with commas, double-quotes, or newlines
//  are wrapped in double-quotes; internal quotes are escaped as "".
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - CSV Document (for fileExporter)

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    var content: String

    init(content: String = "") {
        self.content = content
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.content = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(content.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - CSV Service

struct CSVService {

    // MARK: Date Formatters

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // MARK: Header

    static let csvHeader = "id,keyMessage,subject,dateOfProposition,source,noteTitle,createdAt"

    // MARK: - Export

    /// Generate a CSV string from all propositions.
    static func exportCSV(from propositions: [Proposition]) -> String {
        var csv = csvHeader + "\n"

        for p in propositions {
            let fields: [String] = [
                p.id.uuidString,
                escapeCSV(p.keyMessage),
                escapeCSV(p.subject),
                p.dateOfProposition.map { dateFormatter.string(from: $0) } ?? "",
                escapeCSV(p.source),
                escapeCSV(p.noteTitle),
                isoFormatter.string(from: p.createdAt)
            ]
            csv += fields.joined(separator: ",") + "\n"
        }

        return csv
    }

    /// Escape a field for CSV (RFC 4180).
    /// Fields containing commas, double-quotes, or newlines are wrapped
    /// in double-quotes, and internal double-quotes are doubled.
    static func escapeCSV(_ field: String) -> String {
        let needsQuoting = field.contains(",") ||
                           field.contains("\"") ||
                           field.contains("\n") ||
                           field.contains("\r")
        if needsQuoting {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    // MARK: - Import

    /// Parse a CSV string into ImportedProposition objects.
    static func importCSV(_ csvString: String) throws -> [ImportedProposition] {
        let lines = parseCSVLines(csvString)

        guard lines.count > 1 else {
            throw CSVError.noData
        }

        // Validate header
        let header = parseCSVFields(lines[0])
        guard header.count >= 7 else {
            throw CSVError.invalidHeader
        }

        // Build column index map (supports reordered columns)
        let expectedColumns = ["id", "keymessage", "subject", "dateofproposition", "source", "notetitle", "createdat"]
        var columnIndex: [String: Int] = [:]
        for (i, col) in header.enumerated() {
            let normalized = col.trimmingCharacters(in: .whitespaces).lowercased()
            columnIndex[normalized] = i
        }

        // Check all required columns exist
        for col in expectedColumns {
            guard columnIndex[col] != nil else {
                throw CSVError.invalidHeader
            }
        }

        let idxKeyMessage = columnIndex["keymessage"]!
        let idxSubject = columnIndex["subject"]!
        let idxDate = columnIndex["dateofproposition"]!
        let idxSource = columnIndex["source"]!
        let idxNoteTitle = columnIndex["notetitle"]!
        let idxCreatedAt = columnIndex["createdat"]!

        var result: [ImportedProposition] = []

        for i in 1..<lines.count {
            let fields = parseCSVFields(lines[i])
            guard fields.count >= 7 else { continue }

            let keyMessage = fields[idxKeyMessage]
            let subject = fields[idxSubject]
            let dateStr = fields[idxDate]
            let source = fields[idxSource]
            let noteTitle = fields[idxNoteTitle]
            let createdAtStr = fields[idxCreatedAt]

            // Skip rows with empty key message
            guard !keyMessage.trimmingCharacters(in: .whitespaces).isEmpty else { continue }

            let dateOfProp = dateStr.isEmpty ? nil : dateFormatter.date(from: dateStr)
            let createdAt = isoFormatter.date(from: createdAtStr) ?? Date()

            result.append(ImportedProposition(
                keyMessage: keyMessage,
                subject: subject,
                dateOfProposition: dateOfProp,
                source: source,
                noteTitle: noteTitle,
                createdAt: createdAt
            ))
        }

        if result.isEmpty {
            throw CSVError.noData
        }

        return result
    }

    // MARK: - CSV Parsing (RFC 4180)

    /// Split CSV text into logical lines, respecting quoted fields that span newlines.
    static func parseCSVLines(_ csv: String) -> [String] {
        var lines: [String] = []
        var current = ""
        var inQuotes = false

        for char in csv {
            if char == "\"" {
                inQuotes.toggle()
                current.append(char)
            } else if char == "\n" && !inQuotes {
                let trimmed = current.trimmingCharacters(in: .init(charactersIn: "\r"))
                if !trimmed.isEmpty {
                    lines.append(trimmed)
                }
                current = ""
            } else {
                current.append(char)
            }
        }

        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            lines.append(trimmed)
        }

        return lines
    }

    /// Parse a single CSV line into individual fields, handling quoted values and escaped quotes.
    static func parseCSVFields(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let char = line[i]

            if char == "\"" {
                if inQuotes {
                    // Check for escaped double-quote ("")
                    let next = line.index(after: i)
                    if next < line.endIndex && line[next] == "\"" {
                        current.append("\"")
                        i = line.index(after: next)
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    inQuotes = true
                }
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }

            i = line.index(after: i)
        }

        fields.append(current)
        return fields
    }

    // MARK: - Types

    struct ImportedProposition {
        let keyMessage: String
        let subject: String
        let dateOfProposition: Date?
        let source: String
        let noteTitle: String
        let createdAt: Date
    }

    enum CSVError: LocalizedError {
        case noData
        case invalidHeader

        var errorDescription: String? {
            switch self {
            case .noData:
                return "Keine Daten in der CSV-Datei gefunden."
            case .invalidHeader:
                return "Ungültiger CSV-Header. Erwartet: id, keyMessage, subject, dateOfProposition, source, noteTitle, createdAt"
            }
        }
    }
}
