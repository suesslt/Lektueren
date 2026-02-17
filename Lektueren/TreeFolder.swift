//
//  TreeFolderItem.swift
//  Lektüren
//
//  Created by Thomas Süssli on 16.02.2026.
//
import Foundation

protocol TreeFolder {
    associatedtype Leaf: TreeItem
    var id: UUID { get }
    var name: String { get }
    var icon: String { get }
    var items: [Leaf]? { get }
    var subfolders: [Self]? { get }
    /// Anzahl der direkt in diesem Folder enthaltenen Items (ohne Unterordner).
    /// Bei virtuellen Folders wird die Gesamtzahl aller Items store-weit erwartet.
    var itemCount: Int { get }
    /// Gibt an, ob dieser Folder ein virtueller Pseudo-Ordner ist (z.B. "Alle Lektüren").
    /// Virtuelle Ordner können keine Unterordner erhalten und dienen nicht als Parent.
    var isVirtual: Bool { get }
}
