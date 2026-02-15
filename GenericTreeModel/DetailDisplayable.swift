//
//  DetailDisplayable.swift
//  GenericTreeModel
//
//  Created by Thomas Süssli on 15.02.2026.
//
import SwiftUI

protocol DetailDisplayable: TreeItem {
    var fileSize: String { get }
    var lastModified: Date { get }
    var pdfUrl: URL? { get }
}
