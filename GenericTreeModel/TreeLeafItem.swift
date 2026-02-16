//
//  TreeItem.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import Foundation
import SwiftUI

/// A protocol for leaf nodes in the tree (e.g. PDFItem) — no children.
protocol TreeLeafItem: AnyObject {
    associatedtype RowView: View

    var id: UUID { get }
    var name: String { get set }
    var icon: String { get set }

    /// The view used to represent this item in a list row.
    @ViewBuilder var rowView: RowView { get }
}
