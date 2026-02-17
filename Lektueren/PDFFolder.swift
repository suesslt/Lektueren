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
    var id: UUID = UUID()
    var name: String = ""
    @Transient var icon: String = "folder"
    @Relationship(deleteRule: .nullify, inverse: \PDFItem.folder)
    var items: [PDFItem]?
    var parent: PDFFolder?
    @Relationship(deleteRule: .cascade, inverse: \PDFFolder.parent)
    var storedSubfolders: [PDFFolder]?
    var subfolders: [PDFFolder]? {
        guard let folders = storedSubfolders, !folders.isEmpty else { return nil }
        return folders
    }

    init(
        name: String,
        id: UUID = UUID(),
        items: [PDFItem]? = nil,
        parent: PDFFolder? = nil,
        subfolders: [PDFFolder]? = nil
    ) {
        self.id = id
        self.name = name
        self.items = items
        self.parent = parent
        self.storedSubfolders = subfolders
    }
}
