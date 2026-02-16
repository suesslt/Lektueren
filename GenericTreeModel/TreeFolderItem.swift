//
//  TreeFolderItem.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 16.02.2026.
//
import Foundation

protocol TreeFolderItem {
    associatedtype Leaf: TreeLeafItem
    var id: UUID { get }
    var name: String { get }
    var icon: String { get }
    var children: [Leaf]? { get }
    /// Sub-folders of the same type, used for recursive tree navigation.
    var subfolders: [Self]? { get }
}
