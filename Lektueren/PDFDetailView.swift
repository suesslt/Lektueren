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
        VStack(spacing: 20) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            Text(item.title!)
                .font(.title)

            List {
                LabeledContent("Größe", value: item.fileSize)
                LabeledContent("Zuletzt geändert", value: item.lastModified.formatted(date: .abbreviated, time: .shortened))
            }
            #if os(iOS)
                .listStyle(.insetGrouped)
            #endif
        }
    }
}
