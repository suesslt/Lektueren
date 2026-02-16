//
//  TreeViewModel.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//

import Combine

protocol TreeViewModel: ObservableObject {
    associatedtype Item: TreeItem & Hashable & Identifiable
    
    var rootFolders: [Item] { get }
    var selectedFolder: Item? { get set }
    var selectedDetailItem: Item? { get set } // Falls Details auch TreeItems sind
}
