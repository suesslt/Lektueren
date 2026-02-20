//
//  PDFItemRowView.swift
//  Lektüren
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct PDFItemRowView: View {
    let document: PDFItem
    var onDelete: (() -> Void)?
    var onAIExtract: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            PDFThumbnailView(data: document.thumbnailData)
                .frame(width: 44, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                // Titel: AI-Titel falls vorhanden, sonst PDF-Titel, sonst Dateiname
                Text(displayTitle)
                    .font(.body)
                    .lineLimit(2)

                // Autor: AI-Autor falls vorhanden, sonst PDF-Autor
                if let author = displayAuthor {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Datum und Seitenanzahl in einer Zeile
                HStack(spacing: 8) {
                    // Erstellungsdatum: AI-Datum falls vorhanden, sonst PDF-Datum
                    if let date = displayCreationDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if document.pageCount > 0 {
                        if displayCreationDate != nil {
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("\(document.pageCount) Seiten")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Löschen", systemImage: "trash")
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if let onAIExtract {
                Button {
                    onAIExtract()
                } label: {
                    Label("AI-Extraktion", systemImage: "sparkles")
                }
                .tint(.purple)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Titel: Priorität AI → PDF → Dateiname
    private var displayTitle: String {
        if let aiTitle = document.aiExtractedTitle, !aiTitle.isEmpty {
            return aiTitle
        }
        return document.title ?? document.fileName
    }
    
    /// Autor: Priorität AI → PDF
    private var displayAuthor: String? {
        if let aiAuthor = document.aiExtractedAuthor, !aiAuthor.isEmpty {
            return aiAuthor
        }
        if let pdfAuthor = document.author, !pdfAuthor.isEmpty {
            return pdfAuthor
        }
        return nil
    }
    
    /// Erstellungsdatum: Priorität AI → PDF
    private var displayCreationDate: Date? {
        if let aiDate = document.aiExtractedDate {
            return aiDate
        }
        return document.pdfCreationDate
    }
}



