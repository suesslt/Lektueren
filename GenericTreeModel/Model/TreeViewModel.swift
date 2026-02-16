//
//  TreeViewModel.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//

import Combine

protocol TreeViewModel: ObservableObject {
    associatedtype Item: TreeFolder & Hashable & Identifiable
    
    var rootFolders: [TreeFolder] { get }
    var selectedFolder: TreeFolder? { get set }
    var selectedDetailItem: TreeDetailItem? { get set } // Falls Details auch TreeItems sind
}
