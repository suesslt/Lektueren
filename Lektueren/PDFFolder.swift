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
    // CloudKit does not support unique constraints — remove @Attribute(.unique).
    // SwiftData / CloudKit manages record identity internally via its own CKRecord ID.
    var id: UUID = UUID()
    var name: String = ""       // Must have a default for CloudKit sync
    var icon: String = "folder.fill"

    // The inverse relationship (PDFItem.folder → PDFFolder) satisfies CloudKit's
    // requirement that every relationship has an inverse.
    @Relationship(deleteRule: .nullify, inverse: \PDFItem.folder)
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
