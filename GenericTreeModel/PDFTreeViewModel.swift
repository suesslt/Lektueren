//
//  PDFTreeViewModel.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI
import Combine

class PDFTreeViewModel: TreeViewModel {
    typealias Item = TreeFolder
    
    @Published var rootFolders: [TreeFolder] = []
    @Published var selectedFolder: TreeFolder?
    @Published var selectedDetailItem: TreeDetailItem?
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        let pdf1 = PDFItem(name: "Rechnung_Januar.pdf", fileSize: "1.2 MB", pdfUrl: URL(string: "https://example.com/1.pdf"))
        let pdf2 = PDFItem(name: "Vertrag_final.pdf", fileSize: "4.5 MB", pdfUrl: URL(string: "https://example.com/2.pdf"))
        
        let workFolder = TreeFolder(name: "Arbeit", icon: "folder.fill") // TODO: Add items
        let privateFolder = TreeFolder(name: "Privat", icon: "folder.fill", children: nil)
        
        self.rootFolders = [
            TreeFolder(name: "Meine Dokumente", icon: "archivebox.fill", children: [workFolder, privateFolder])
        ]
    }
}
