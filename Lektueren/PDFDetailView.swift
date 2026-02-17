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

            Section("Allgemein") {
                if let author = item.author, !author.isEmpty {
                    LabeledContent("Autor", value: author)
                }
                if !item.fileName.isEmpty {
                    LabeledContent("Dateiname", value: item.fileName)
                }
                LabeledContent("Seitenanzahl", value: item.pageCount, format: .number)
                LabeledContent("Größe", value: item.fileSize)
            }

            Section("Datum") {
                LabeledContent("Zuletzt geändert") {
                    Text(item.lastModified.formatted(date: .abbreviated, time: .shortened))
                }
            }

            Section("Speicherort") {
                if let folder = item.folder {
                    LabeledContent("Ordner", value: folder.name ?? "–")
                }
                if let url = item.pdfUrl {
                    LabeledContent("Pfad", value: url.path(percentEncoded: false))
                        .truncationMode(.middle)
                }
            }

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
