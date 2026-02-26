//
//  FindingsReportDetailView.swift
//  Lektüren
//
//  Detail-Ansicht für einen Erkenntnisbericht.
//  Zeigt das generierte PDF mit PDFKit an und bietet Share-Funktionalität.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct FindingsReportDetailView: View {
    let report: FindingsReport
    let onDelete: () -> Void

    var body: some View {
        Group {
            if let pdfData = report.pdfData {
                FindingsReportPDFView(data: pdfData)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                ContentUnavailableView(
                    "Kein PDF",
                    systemImage: "doc.richtext",
                    description: Text("Der Bericht hat noch kein generiertes PDF.")
                )
            }
        }
        .navigationTitle(report.topic)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let pdfData = report.pdfData {
                    ShareLink(
                        item: PDFDataItem(data: pdfData, filename: pdfFilename),
                        preview: SharePreview(report.topic, image: Image(systemName: "doc.richtext"))
                    )
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Löschen", systemImage: "trash")
                }
            }
        }
    }

    private var pdfFilename: String {
        let sanitized = report.topic
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        return "Erkenntnisbericht_\(sanitized).pdf"
    }
}

// MARK: - PDF View aus Data

private struct FindingsReportPDFView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.dataRepresentation() != data {
            uiView.document = PDFDocument(data: data)
        }
    }
}

// MARK: - Transferable für ShareLink

struct PDFDataItem: Transferable {
    let data: Data
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { item in
            item.data
        }
    }
}
