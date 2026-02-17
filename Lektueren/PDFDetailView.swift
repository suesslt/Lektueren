//
//  PDFDetailView.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI
import PDFKit

struct PDFDetailView: View {
    let item: PDFItem

    @State private var isInspectorPresented: Bool = true

    var body: some View {
        PDFKitView(url: item.pdfUrl)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(item.title ?? item.fileName)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation {
                            isInspectorPresented.toggle()
                        }
                    } label: {
                        Label(
                            isInspectorPresented ? "Informationen ausblenden" : "Informationen anzeigen",
                            systemImage: "sidebar.right"
                        )
                    }
                }
            }
            .inspector(isPresented: $isInspectorPresented) {
                PDFInspectorView(item: item)
                    .inspectorColumnWidth(min: 260, ideal: 300, max: 400)
            }
    }
}

// MARK: - PDFKit View (UIViewRepresentable / NSViewRepresentable)

private struct PDFKitView: View {
    let url: URL?

    var body: some View {
        if let url {
            #if os(macOS)
            MacPDFView(url: url)
            #else
            iOSPDFView(url: url)
            #endif
        } else {
            ContentUnavailableView(
                "Keine Datei",
                systemImage: "doc.richtext",
                description: Text("Der Pfad zur PDF-Datei ist nicht verfügbar.")
            )
        }
    }
}

#if os(macOS)
private struct MacPDFView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document?.documentURL != url {
            nsView.document = PDFDocument(url: url)
        }
    }
}
#else
private struct iOSPDFView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.usePageViewController(true)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}
#endif

// MARK: - Inspector Panel

private struct PDFInspectorView: View {
    let item: PDFItem

    var body: some View {
        List {
            // MARK: Header
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        PDFThumbnailView(data: item.thumbnailData)
                            .frame(width: 72, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        Text(item.title ?? item.fileName)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .padding(.vertical, 6)
            }

            // MARK: Allgemein
            Section("Allgemein") {
                if let author = item.author, !author.isEmpty {
                    LabeledContent("Autor", value: author)
                }
                if let subject = item.subject, !subject.isEmpty {
                    LabeledContent("Thema", value: subject)
                }
                if !item.keywords.isEmpty {
                    LabeledContent("Stichwörter", value: item.keywords.joined(separator: ", "))
                }
                if !item.fileName.isEmpty {
                    LabeledContent("Dateiname", value: item.fileName)
                }
                LabeledContent("Seitenanzahl", value: item.pageCount, format: .number)
                LabeledContent("Größe", value: item.fileSize)
                if item.isEncrypted {
                    LabeledContent("Verschlüsselt", value: "Ja")
                }
            }

            // MARK: Seitenformat
            if let width = item.pageWidth, let height = item.pageHeight {
                Section("Seitenformat") {
                    LabeledContent("Breite", value: width, format: .number.precision(.fractionLength(1)))
                    LabeledContent("Höhe", value: height, format: .number.precision(.fractionLength(1)))
                    if let rotation = item.pageRotation, rotation != 0 {
                        LabeledContent("Rotation", value: "\(rotation)°")
                    }
                }
            }

            // MARK: Datum
            Section("Datum") {
                if let creationDate = item.pdfCreationDate {
                    LabeledContent("Erstellt (PDF)") {
                        Text(creationDate.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                if let modDate = item.pdfModificationDate {
                    LabeledContent("Geändert (PDF)") {
                        Text(modDate.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                LabeledContent("Geändert (Datei)") {
                    Text(item.lastModified.formatted(date: .abbreviated, time: .shortened))
                }
            }

            // MARK: Werkzeuge
            Section("Werkzeuge") {
                if let creator = item.creator, !creator.isEmpty {
                    LabeledContent("Erstellt mit", value: creator)
                }
                if let producer = item.producer, !producer.isEmpty {
                    LabeledContent("PDF-Bibliothek", value: producer)
                }
            }

            // MARK: Speicherort
            Section("Speicherort") {
                if let folder = item.folder {
                    LabeledContent("Ordner", value: folder.name ?? "–")
                }
                if let url = item.pdfUrl {
                    LabeledContent("Pfad", value: url.path(percentEncoded: false))
                        .truncationMode(.middle)
                }
            }

            // MARK: Technisch
            Section("Technisch") {
                LabeledContent("ID", value: item.id.uuidString)
                    .font(.caption)
                if !item.contentHash.isEmpty {
                    LabeledContent("Hash", value: item.contentHash)
                        .font(.caption)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .navigationTitle("Informationen")
    }
}
