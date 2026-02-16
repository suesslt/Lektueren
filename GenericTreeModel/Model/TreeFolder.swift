//
//  TreeItem.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import Foundation
import SwiftData

@Model
final class TreeFolder {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var icon: String
    
    @Relationship(deleteRule: .cascade, inverse: \TreeFolder.parent)
    var children: [TreeFolder]? = nil
    var parent: TreeFolder?
    
    @Relationship(deleteRule: .nullify, inverse: \TreeDetailItem.folder)
    var items: [TreeDetailItem]? = nil
    
    init(
        name: String,
        icon: String,
        children: [TreeFolder]? = nil,
        parent: TreeFolder? = nil,
        items: [TreeDetailItem]? = nil
    ) {
        self.name = name
        self.icon = icon
        self.children = children
        self.parent = parent
        self.items = items
    }
}
