//
//  TreeItem.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import Foundation

/// Ein Blatt-Knoten im Baum (z. B. PDFItem) – hat keine Kinder.
protocol TreeLeafItem {
    var id: UUID { get }
    var name: String { get }
    var icon: String { get }
}
