//
//  TreeItem.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import Foundation
import SwiftUI

protocol TreeItem {
    associatedtype RowView: View

    var id: UUID { get }
    var name: String { get set }
    var icon: String { get set }

    @ViewBuilder var rowView: RowView { get }
}
