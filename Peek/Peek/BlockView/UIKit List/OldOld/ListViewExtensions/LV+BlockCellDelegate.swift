//
//  NewBlockListViewController+BlockCellDelegate.swift
//  Peek
//
//  Created by Til Blechschmidt on 07.03.21.
//

import Foundation

extension NewBlockListViewController: BlockCellDelegate {
    func blockCellWasSwipedLeft(_ blockCell: BlockCell) {
        editorState.isEditingContent = false
        editorState.focusEngine.select(blockCell.block.id)
    }

    func blockCellDidChangeLayout(_ blockCell: BlockCell, animate: Bool) {
        // Reload the same snapshot to force the layout system to re-think its existence :D
        let snapshot = dataSource.snapshot()
        dataSource.apply(snapshot, animatingDifferences: animate)
    }
}
