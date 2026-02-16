//
//  PDFTreeViewModel.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI
import Combine

class PDFTreeViewModel: TreeViewModel {
    typealias Folder = PDFFolder
    typealias Leaf = PDFItem

    @Published var rootFolders: [PDFFolder] = []
    @Published var selectedFolder: PDFFolder?
    @Published var selectedDetailItem: PDFItem?

    init() {
        loadSampleData()
    }

    private func loadSampleData() {
        let pdf1 = PDFItem(title: "Asia report", fileName: "Rechnung_Januar.pdf", fileSize: "1.2 MB", pdfUrl: URL(string: "https://example.com/1.pdf"))
        let pdf2 = PDFItem(title: "Blick Bericht", fileName: "Vertrag_final.pdf", fileSize: "4.5 MB", pdfUrl: URL(string: "https://example.com/2.pdf"))

        let workFolder = PDFFolder(name: "Arbeit", icon: "folder.fill", items: [pdf1, pdf2])
        let privateFolder = PDFFolder(name: "Privat", icon: "folder.fill")

        let root = PDFFolder(
            name: "Meine Dokumente",
            icon: "archivebox.fill",
            subfolders: [workFolder, privateFolder]
        )

        self.rootFolders = [root]
    }
}
