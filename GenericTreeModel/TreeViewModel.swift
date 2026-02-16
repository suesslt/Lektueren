//
//  TreeViewModel.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//

import Combine

protocol TreeViewModel: ObservableObject {
    associatedtype Folder: TreeFolderItem & Hashable & Identifiable
    associatedtype Leaf: TreeLeafItem & Hashable & Identifiable
        where Folder.Leaf == Leaf

    var rootFolders: [Folder] { get }
    var selectedFolder: Folder? { get set }
    var selectedDetailItem: Leaf? { get set }
}
