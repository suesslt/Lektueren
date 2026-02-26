//
//  NotesService.swift
//  Propositions
//
//  Reads Apple Notes exported as .md (Markdown) files from a folder.
//  Apple Notes → Export All Notes → select folder → this service reads them.
//  Recursively scans the folder for *.md files.
//  File name (without extension) = note title, file contents = note body.
//

import Foundation

struct NoteItem: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let body: String
}

final class NotesService: Sendable {

    static let shared = NotesService()

    /// Read all .md files from a directory (and its subdirectories).
    /// - Parameter folderURL: The root folder containing exported Apple Notes as .md files.
    /// - Returns: Array of NoteItem parsed from the .md files.
    func readMarkdownNotes(from folderURL: URL) throws -> [NoteItem] {
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw NotesError.readFailed(
                "Ordner konnte nicht gelesen werden: \(folderURL.lastPathComponent)"
            )
        }

        var notes: [NoteItem] = []

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "md" else { continue }

            do {
                let body = try String(contentsOf: fileURL, encoding: .utf8)
                let title = fileURL.deletingPathExtension().lastPathComponent

                // Skip empty or very short notes
                guard !title.isEmpty, body.count > 10 else { continue }

                notes.append(NoteItem(title: title, body: body))
            } catch {
                // Skip files that can't be read (e.g. encoding issues)
                continue
            }
        }

        if notes.isEmpty {
            throw NotesError.noNotes
        }

        return notes
    }

    // MARK: - Errors

    enum NotesError: LocalizedError, Sendable {
        case readFailed(String)
        case noNotes

        var errorDescription: String? {
            switch self {
            case .readFailed(let msg):
                return "Fehler: \(msg)"
            case .noNotes:
                return "Keine Markdown-Notizen (.md) im ausgewählten Ordner gefunden."
            }
        }
    }
}
