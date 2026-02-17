//
//  PDFDetailView.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct PDFDetailView: View {
    let item: PDFItem

    var body: some View {
        List {
            // MARK: Header
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        PDFThumbnailView(data: item.thumbnailData)
                            .frame(width: 90, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                        Text(item.title ?? item.fileName)
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .padding(.vertical, 8)
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
        .navigationTitle(item.title ?? item.fileName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
