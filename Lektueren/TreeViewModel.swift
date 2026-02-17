//
//  TreeViewModel.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import Foundation
/// Basis-Protokoll für alle Baum-ViewModels.
/// Nutzt AnyObject statt ObservableObject, damit @Observable-Klassen
/// dieses Protokoll erfüllen können.
@MainActor
protocol TreeViewModel: AnyObject {
    associatedtype Folder: TreeFolder & Hashable & Identifiable
    associatedtype Leaf: TreeItem & Hashable & Identifiable where Folder.Leaf == Leaf

    var rootFolders: [Folder] { get }
    var selectedFolder: Folder? { get set }
    var selectedDetailItem: Leaf? { get set }

    /// Erstellt einen neuen Folder mit dem angegebenen Namen.
    /// Wenn `parent` nil ist, wird ein Root-Folder angelegt.
    func addFolder(name: String, parent: Folder?)

    /// Importiert Items aus den angegebenen URLs in den angegebenen Ordner.
    func importItems(from urls: [URL], into folder: Folder)

    #if DEBUG
    /// Löscht alle Folders und Items. Nur für Entwicklungszwecke.
    func deleteAll()
    #endif
}
