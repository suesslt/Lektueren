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
    var items: [Leaf]? { get }
    var subfolders: [Self]? { get }
}
