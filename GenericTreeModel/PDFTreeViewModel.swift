//
//  PDFTreeViewModel.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI
import Combine

class PDFTreeViewModel: TreeViewModel {
    typealias Item = PDFItem
    
    @Published var rootFolders: [PDFItem] = []
    @Published var selectedFolder: PDFItem?
    @Published var selectedDetailItem: PDFItem?
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        let pdf1 = PDFItem(name: "Rechnung_Januar.pdf", icon: "doc.richtext", children: nil, fileSize: "1.2 MB", pdfUrl: URL(string: "https://example.com/1.pdf"))
        let pdf2 = PDFItem(name: "Vertrag_final.pdf", icon: "doc.richtext", children: nil, fileSize: "4.5 MB", pdfUrl: URL(string: "https://example.com/2.pdf"))
        
        let workFolder = PDFItem(name: "Arbeit", icon: "folder.fill", children: [pdf1, pdf2])
        let privateFolder = PDFItem(name: "Privat", icon: "folder.fill", children: nil)
        
        self.rootFolders = [
            PDFItem(name: "Meine Dokumente", icon: "archivebox.fill", children: [workFolder, privateFolder])
        ]
    }
}
