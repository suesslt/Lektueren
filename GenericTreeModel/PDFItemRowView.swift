//
//  PDFItemRowView.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct PDFItemRowView: View {
    let document: PDFItem

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
//            DocumentThumbnail(document: document)
//                .frame(width: 44, height: 60)
//                .clipShape(RoundedRectangle(cornerRadius: 4))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title ?? document.fileName)
                    .font(.body)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let author = document.author, !author.isEmpty {
                        Text(author)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if document.pageCount > 0 {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\(document.pageCount) Seiten")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
