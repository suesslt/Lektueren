//
//  GenericDetailView.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct GenericDetailView<T: DetailDisplayable>: View {
    let item: T

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: item.pdfUrl != nil ? "doc.pdf.fill" : "folder.badge.questionmark")
                .font(.system(size: 80))
                .foregroundColor(.red)

            Text(item.name)
                .font(.title)

            List {
                LabeledContent("Größe", value: item.fileSize)
                LabeledContent("Geändert", value: item.lastModified.formatted(date: .abbreviated, time: .shortened))
                if let url = item.pdfUrl {
                    Link("Im Browser öffnen", destination: url)
                        .buttonStyle(.borderedProminent)
                }
            }
            #if os(iOS)
                .listStyle(.insetGrouped)
            #endif
        }
    }
}
