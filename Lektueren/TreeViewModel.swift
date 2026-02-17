//
//  TreeViewModel.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import Foundation

@MainActor
protocol TreeViewModel: AnyObject {
    associatedtype Folder: TreeFolder & Hashable & Identifiable
    associatedtype Leaf: TreeItem & Hashable & Identifiable where Folder.Leaf == Leaf

    var rootFolders: [Folder] { get }
    var selectedFolder: Folder? { get set }
    var selectedDetailItem: Leaf? { get set }

    /// Die aktuell anzuzeigenden Items.
    /// Bei einem virtuellen Folder (z.B. "Alle Lektüren") werden alle Items
    /// store-weit geliefert; sonst die Items des selektierten Folders.
    var displayedItems: [Leaf] { get }

    func addFolder(name: String, parent: Folder?)

    /// Importiert Items aus den angegebenen URLs in den angegebenen Ordner.
    func importItems(from urls: [URL], into folder: Folder)

    #if DEBUG
    func deleteAll()
    #endif
}
