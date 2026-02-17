//
//  PDFThumbnailView.swift
//  Lektüren
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

struct PDFThumbnailView: View {
    let data: Data?

    #if os(macOS)
    private var image: Image? {
        guard let data, let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
    }
    #else
    private var image: Image? {
        guard let data, let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }
    #endif

    var body: some View {
        if let image {
            image
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "doc.richtext")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
        }
    }
}
