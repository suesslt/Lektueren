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
        let pdf1 = PDFItem(title: "Asia report", fileName: "Rechnung_Januar.pdf", author: "Michael Brabeck", pageCount: 18, fileSize: "1.2 MB", pdfUrl: URL(string: "https://example.com/1.pdf"))
        let pdf2 = PDFItem(title: "Blick Bericht", fileName: "Vertrag_final.pdf", author: "John Sullivan", pageCount: 129, fileSize: "4.5 MB", pdfUrl: URL(string: "https://example.com/2.pdf"))
        let pdf3 = PDFItem(title: "Ukraine Story", fileName: "Ukraine_at_the_trenches.pdf", author: "Mark Hubbard", pageCount: 4, fileSize: "20 KB", pdfUrl: URL(string: "https://example.com/ukraine.pdf"))

        let workFolder = PDFFolder(name: "Arbeit", icon: "folder.fill", items: [pdf1, pdf2])
        let privateFolder = PDFFolder(name: "Privat", icon: "folder.fill", items: [pdf3])

        let root = PDFFolder(
            name: "Meine Dokumente",
            icon: "archivebox.fill",
            subfolders: [workFolder, privateFolder]
        )

        let allItems = allItems(in: [root])
        let allPDFsFolder = PDFFolder(name: "Alle PDFs", icon: "tray.full.fill", items: allItems)

        self.rootFolders = [allPDFsFolder, root]
    }

    /// Recursively collects all `PDFItem` leaves from the given folders
    /// and all of their nested subfolders.
    func allItems(in folders: [PDFFolder]) -> [PDFItem] {
        folders.flatMap { folder -> [PDFItem] in
            let ownItems = folder.items ?? []
            let childItems = allItems(in: folder.subfolders ?? [])
            return ownItems + childItems
        }
    }
}
