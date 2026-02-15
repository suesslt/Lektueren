//
//  TreeItem.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import Foundation

protocol TreeItem: AnyObject {
    var id: UUID { get }
    var name: String { get }
    var icon: String { get }
    var children: [Self]? { get }
    var treeChildren: [Self]? { get }
}

extension TreeItem {
    /// Gibt `nil` zurück wenn keine Kinder vorhanden sind,
    /// damit SwiftUI kein Expand-Icon für leere Arrays anzeigt.
    var treeChildren: [Self]? {
        guard let children, !children.isEmpty else { return nil }
        return children
    }
}
