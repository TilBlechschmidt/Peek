//
//  BlockManager+BlockEditorDelegate.swift
//  Peek
//
//  Created by Til Blechschmidt on 18.04.21.
//

import UIKit

extension BlockManager: BlockEditorDelegate {
    func registerCells(with tableView: UITableView) {
//        tableView.register(ContentCellA.self, forCellReuseIdentifier: ContentCellA.identifier)
        tableView.register(TextBlockEditorCell.self, forCellReuseIdentifier: TextBlockEditorCell.identifier)
    }

    func cellIdentifier(for block: UUID) -> String {
//        let index = blockManager.allItems().firstIndex(of: block) ?? 0
//        return index % 2 == 0 ? ContentCellA.identifier : ContentCellB.identifier
        return TextBlockEditorCell.identifier
    }

    func configure(cell: BlockEditorCell, for block: UUID) {
//        if let cell = cell as? ContentCellA {
//            cell.textLabel?.text = "ContentA \(block)"
//        } else
        if let cell = cell as? TextBlockEditorCell {
            cell.set(text: "ContentB \(block)")
        }
    }
}
