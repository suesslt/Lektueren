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
    var id: UUID = UUID()
    var title: String?
    var fileName: String = ""
    var author: String?
    var pageCount: Int = 0
    var fileSize: String = ""
    var lastModified: Date = Date()
    var pdfUrl: URL? = nil
    var contentHash: String = ""
    var thumbnailData: Data?
    var folder: PDFFolder?

    init(
        title: String,
        fileName: String = "",
        author: String = "",
        pageCount: Int = 0,
        fileSize: String = "",
        lastModified: Date = Date(),
        pdfUrl: URL? = nil,
        contentHash: String = "",
        thumbnailData: Data? = nil
    ) {
        self.title = title
        self.fileName = fileName
        self.author = author
        self.pageCount = pageCount
        self.fileSize = fileSize
        self.lastModified = lastModified
        self.pdfUrl = pdfUrl
        self.contentHash = contentHash
        self.thumbnailData = thumbnailData
    }

    var rowView: some View {
        PDFItemRowView(document: self)
    }
}
