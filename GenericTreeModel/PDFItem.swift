//
//  PDFItem.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftData
import SwiftUI

@Model
final class PDFItem: TreeItem {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var icon: String = "doc.richtext"
    var fileSize: String = "0 KB"
    var lastModified: Date = Date()
    var pdfUrl: URL? = nil

    @Relationship
    var folder: PDFFolder?

    init(
        name: String = "",
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

    var rowView: some View {
        PDFItemRowView(item: self)
    }
}
