//
//  TreeItem.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import Foundation

protocol TreeFolder {
    var id: UUID { get }
    var name: String { get }
    var icon: String { get }
    var children: [Self]? { get }
}
