//
//  FindingsReport.swift
//  Lektüren
//
//  SwiftData Model für Erkenntnisberichte.
//  Speichert Thema, Markdown-Inhalt und generiertes PDF.
//

import Foundation
import SwiftData

@Model
final class FindingsReport {
    var id: UUID = UUID()
    var topic: String = ""
    var markdownContent: String = ""
    var pdfData: Data?
    var createdAt: Date = Date()

    init(topic: String, markdownContent: String, pdfData: Data? = nil) {
        self.id = UUID()
        self.topic = topic
        self.markdownContent = markdownContent
        self.pdfData = pdfData
        self.createdAt = Date()
    }
}
