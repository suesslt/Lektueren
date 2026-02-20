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
    
    /// Relativer Pfad zur PDF-Datei im iCloud-Container (nur Dateiname).
    /// Die vollständige URL wird zur Laufzeit mit `pdfUrl` rekonstruiert.
    var pdfRelativePath: String = ""
    
    /// Flag: true = Datei liegt in iCloud, false = lokale Datei
    var isCloudFile: Bool = true
    
    var contentHash: String = ""
    var thumbnailData: Data?
    var folder: PDFFolder?
    
    // MARK: - AI-extrahierte Metadaten
    var aiExtractedTitle: String?
    var aiExtractedAuthor: String?
    var aiExtractedDate: Date?
    var aiSummary: String?
    var aiKeywords: [String] = []
    
    // MARK: - Computed URL
    
    /// Gibt die vollständige URL zur PDF-Datei zurück.
    /// Für iCloud-Dateien wird die URL zur Laufzeit aus dem relativen Pfad rekonstruiert.
    var pdfUrl: URL? {
        guard !pdfRelativePath.isEmpty else { return nil }
        
        if isCloudFile {
            // iCloud-URL zur Laufzeit rekonstruieren
            guard let cloudDirectory = try? PDFCloudStorage.cloudPDFDirectory() else {
                return nil
            }
            return cloudDirectory.appendingPathComponent(pdfRelativePath)
        } else {
            // Lokale Datei - relativer Pfad ist eigentlich die komplette URL als String
            return URL(string: pdfRelativePath)
        }
    }

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
        pdfRelativePath: String = "",
        isCloudFile: Bool = true,
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
        self.pdfRelativePath = pdfRelativePath
        self.isCloudFile = isCloudFile
        self.contentHash = contentHash
        self.thumbnailData = thumbnailData
    }

    var rowView: some View {
        PDFItemRowView(document: self)
    }
}
