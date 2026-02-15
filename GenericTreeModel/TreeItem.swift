//
//  TreeItem.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//


protocol TreeItem: Identifiable, Hashable {
    var name: String { get }
    var icon: String { get }
    var children: [Self]? { get }
}
