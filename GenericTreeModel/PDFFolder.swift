//
//  PDFFolder.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 16.02.2026.
//
import SwiftUI
import SwiftData

@Model
final class PDFFolder: TreeFolder {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var icon: String

    @Relationship(deleteRule: .cascade, inverse: \PDFItem.folder)
    var items: [PDFItem]?

    var parent: PDFFolder?

    @Relationship(deleteRule: .cascade, inverse: \PDFFolder.parent)
    var subfolders: [PDFFolder]?

    init(
        name: String,
        icon: String = "folder.fill",
        items: [PDFItem]? = nil,
        parent: PDFFolder? = nil,
        subfolders: [PDFFolder]? = nil
    ) {
        self.name = name
        self.icon = icon
        self.items = items
        self.parent = parent
        self.subfolders = subfolders
    }
}
