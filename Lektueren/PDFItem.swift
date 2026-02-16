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
    // CloudKit does not support unique constraints — remove @Attribute(.unique).
    var id: UUID = UUID()
    var title: String?
    var fileName: String = ""       // Must have a default for CloudKit sync
    var author: String?
    var pageCount: Int = 0          // Must have a default for CloudKit sync
    var fileSize: String = "0 KB"   // Must have a default for CloudKit sync
    var lastModified: Date = Date()
    var pdfUrl: URL? = nil

    // Inverse relationship required by CloudKit.
    // PDFFolder.items uses `inverse: \PDFItem.folder`, so this must exist.
    var folder: PDFFolder?

    init(
        title: String = "",
        fileName: String = "",
        author: String = "",
        pageCount: Int = 0,
        fileSize: String = "0 KB",
        lastModified: Date = Date(),
        pdfUrl: URL? = nil
    ) {
        self.title = title
        self.fileName = fileName
        self.author = author
        self.pageCount = pageCount
        self.fileSize = fileSize
        self.lastModified = lastModified
        self.pdfUrl = pdfUrl
    }

    var rowView: some View {
        PDFItemRowView(document: self)
    }
}
