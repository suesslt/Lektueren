//
//  PDFItem.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct PDFItem: DetailDisplayable {
    let id = UUID()
    let name: String
    let icon: String
    var children: [PDFItem]? // Für Unterordner
    
    // Detail-Spezifische Felder
    var fileSize: String = "0 KB"
    var lastModified: Date = Date()
    var pdfUrl: URL? = nil
}
