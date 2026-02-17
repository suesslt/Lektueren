//
//  PDFItem.swift
//  Lektüren
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
    var subject: String?
    var creator: String?
    var producer: String?
    var keywords: [String] = []
    var pageCount: Int = 0
    var pageWidth: Double?
    var pageHeight: Double?
    var pageRotation: Int?
    var isEncrypted: Bool = false
    var fileSize: String = ""
    var lastModified: Date = Date()
    var pdfCreationDate: Date?
    var pdfModificationDate: Date?
    var pdfUrl: URL? = nil
    var contentHash: String = ""
    var thumbnailData: Data?
    var folder: PDFFolder?

    init(
        title: String,
        fileName: String = "",
        author: String = "",
        subject: String? = nil,
        creator: String? = nil,
        producer: String? = nil,
        keywords: [String] = [],
        pageCount: Int = 0,
        pageWidth: Double? = nil,
        pageHeight: Double? = nil,
        pageRotation: Int? = nil,
        isEncrypted: Bool = false,
        fileSize: String = "",
        lastModified: Date = Date(),
        pdfCreationDate: Date? = nil,
        pdfModificationDate: Date? = nil,
        pdfUrl: URL? = nil,
        contentHash: String = "",
        thumbnailData: Data? = nil
    ) {
        self.title = title
        self.fileName = fileName
        self.author = author
        self.subject = subject
        self.creator = creator
        self.producer = producer
        self.keywords = keywords
        self.pageCount = pageCount
        self.pageWidth = pageWidth
        self.pageHeight = pageHeight
        self.pageRotation = pageRotation
        self.isEncrypted = isEncrypted
        self.fileSize = fileSize
        self.lastModified = lastModified
        self.pdfCreationDate = pdfCreationDate
        self.pdfModificationDate = pdfModificationDate
        self.pdfUrl = pdfUrl
        self.contentHash = contentHash
        self.thumbnailData = thumbnailData
    }

    var rowView: some View {
        PDFItemRowView(document: self)
    }
}
