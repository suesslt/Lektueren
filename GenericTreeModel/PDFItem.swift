//
//  PDFItem.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftData
import SwiftUI

@Model
final class PDFItem: TreeLeafItem {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var icon: String
    var fileSize: String = "0 KB"
    var lastModified: Date = Date()
    var pdfUrl: URL? = nil

    @Relationship
    var folder: PDFFolder?

    init(
        name: String,
        icon: String = "doc.richtext",
        fileSize: String = "0 KB",
        lastModified: Date = Date(),
        pdfUrl: URL? = nil
    ) {
        self.name = name
        self.icon = icon
        self.fileSize = fileSize
        self.lastModified = lastModified
        self.pdfUrl = pdfUrl
    }
}

// MARK: - PDFFolder (Ordner)

@Model
final class PDFFolder: TreeFolderItem {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var icon: String

    @Relationship(deleteRule: .cascade, inverse: \PDFItem.folder)
    var children: [PDFItem]?

    var parent: PDFFolder?

    @Relationship(deleteRule: .cascade, inverse: \PDFFolder.parent)
    var subfolders: [PDFFolder]?

    init(
        name: String,
        icon: String = "folder.fill",
        children: [PDFItem]? = nil,
        parent: PDFFolder? = nil,
        subfolders: [PDFFolder]? = nil
    ) {
        self.name = name
        self.icon = icon
        self.children = children
        self.parent = parent
        self.subfolders = subfolders
    }
}
