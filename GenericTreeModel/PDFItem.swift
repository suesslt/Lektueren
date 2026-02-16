import SwiftData
//
//  PDFItem.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

@Model
final class PDFItem : TreeDetailItem {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    @Relationship
    var folder: TreeFolder?

    // Detail-Spezifische Felder
    var fileSize: String = "0 KB"
    var lastModified: Date = Date()
    var pdfUrl: URL? = nil

    init(
        name: String,
        folder: TreeFolder? = nil,
        fileSize: String = "0 KB",
        lastModified: Date = Date(),
        pdfUrl: URL? = nil
    ) {
        self.name = name
        self.folder = folder
        self.fileSize = fileSize
        self.lastModified = lastModified
        self.pdfUrl = pdfUrl
    }
}
