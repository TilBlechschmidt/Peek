//
//  LV+BlockManagerDelegate.swift
//  Peek
//
//  Created by Til Blechschmidt on 14.03.21.
//

import UIKit
import MarkdownKit

extension NewBlockListViewController: BlockManagerDelegate {
    func blockWillChangeContent(from oldContent: Block.Content, to newContent: Block.Content, _ block: UIBlock) {
        if BlockCell.reuseIdentifier(for: oldContent) != BlockCell.reuseIdentifier(for: newContent) {
            // We have to defer the update to the cell until the content actually changed
            DispatchQueue.main.async {
                self.reloadBlock(withId: block.id)
            }
        }
    }

    private func reloadBlock(withId identifier: Block.ID) {
        currentSnapshot = dataSource.snapshot()
        currentSnapshot.reloadItems([identifier])
        dataSource.apply(currentSnapshot, animatingDifferences: true)
    }
}
