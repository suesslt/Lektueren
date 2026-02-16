//
//  TreeViewModel.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//

/// Basis-Protokoll für alle Baum-ViewModels.
/// Nutzt AnyObject statt ObservableObject, damit @Observable-Klassen
/// dieses Protokoll erfüllen können.
@MainActor
protocol TreeViewModel: AnyObject {
    associatedtype Folder: TreeFolder & Hashable & Identifiable
    associatedtype Leaf: TreeItem & Hashable & Identifiable
        where Folder.Leaf == Leaf

    var rootFolders: [Folder] { get }
    var selectedFolder: Folder? { get set }
    var selectedDetailItem: Leaf? { get set }
}
