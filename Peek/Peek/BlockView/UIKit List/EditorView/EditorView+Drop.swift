//
//  EditorView+Drop.swift
//  Peek
//
//  Created by Til Blechschmidt on 19.04.21.
//

import UIKit

extension BlockEditorViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let indexPath = coordinator.destinationIndexPath else { return }

        for item in coordinator.items.reversed() {
            guard let interaction = item.dragItem.localObject as? BlockEditorDragInteraction else { continue }

            let content = interaction.commit()
            delegate?.insert(content, at: indexPath.row)
            coordinator.drop(item.dragItem, toRowAt: indexPath)
        }
    }
}
