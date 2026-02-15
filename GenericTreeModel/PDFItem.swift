import SwiftData
//
//  PDFItem.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

@Model
final class PDFItem: TreeFolder {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var icon: String
    
    @Relationship(deleteRule: .cascade, inverse: \PDFItem.parent)
    var children: [PDFItem]?
    var parent: PDFItem?

    // Detail-Spezifische Felder
    var fileSize: String = "0 KB"
    var lastModified: Date = Date()
    var pdfUrl: URL? = nil

    init(
        name: String,
        icon: String,
        children: [PDFItem]? = nil,
        parent: PDFItem? = nil,
        fileSize: String = "0 KB",
        lastModified: Date = Date(),
        pdfUrl: URL? = nil
    ) {
        self.name = name
        self.icon = icon
        self.children = children
        self.parent = parent
        self.fileSize = fileSize
        self.lastModified = lastModified
        self.pdfUrl = pdfUrl
    }
}
