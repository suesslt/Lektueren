//
//  PDFItemRowView.swift
//  Lektüren
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct PDFItemRowView: View {
    let document: PDFItem

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            PDFThumbnailView(data: document.thumbnailData)
                .frame(width: 44, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)

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



