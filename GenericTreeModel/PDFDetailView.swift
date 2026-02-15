//
//  GenericDetailView.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct PDFDetailView<T: TreeFolder>: View {
    let item: T

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 80))
                .foregroundColor(.red)

            Text(item.name)
                .font(.title)

            List {
                LabeledContent("Größe", value: "102 KB")
            }
            #if os(iOS)
                .listStyle(.insetGrouped)
            #endif
        }
    }
}
