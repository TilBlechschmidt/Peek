//
//  EditorView+Drop.swift
//  Peek
//
//  Created by Til Blechschmidt on 19.04.21.
//

import UIKit

extension BlockEditorViewController: UIDropInteractionDelegate {
    func configureDropInteraction() {
        tableView.addInteraction(UIDropInteraction(delegate: self))
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        let dropLocation = session.location(in: tableView)

        let sameInstanceSourceBlockIDs = session.items.compactMap { (item: UIDragItem) -> UUID? in
            guard let interaction = item.localObject as? BlockEditorDragInteraction, interaction.sourceDelegateInstance == delegate?.instance else { return nil }
            return interaction.content.id
        }

        if let indexPath = tableView.indexPathForRow(at: dropLocation), let cell = tableView.cellForRow(at: indexPath), let blockID = dataSource.itemIdentifier(for: indexPath) {
            let above = session.location(in: cell).y < cell.frame.height / 2
            dragState.target = (blockID, above)

            if sameInstanceSourceBlockIDs.contains(blockID) {
                return UIDropProposal(operation: .cancel)
            }
        } else {
            // TODO Scrolling and snap to first/last
            dragState.target = nil
            return UIDropProposal(operation: .forbidden)
        }

        let proposal = UIDropProposal(operation: session.allowsMoveOperation ? .move : .copy)
        proposal.prefersFullSizePreview = true
        return proposal
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let delegate = delegate, let target = dragState.target else { return }

        var isSameInstance = false

        let contents = session.items.compactMap { (item: UIDragItem) -> ContentBlock? in
            guard let interaction = item.localObject as? BlockEditorDragInteraction else { return nil }

            interaction.destinationDelegateInstance = delegate.instance

            if interaction.sourceDelegateInstance == interaction.destinationDelegateInstance {
                delegate.remove(interaction.content.id)
                isSameInstance = true
            }

            return interaction.content
        }

        // When moving items within the same tableView, we have to force an intermediate
        // update of the table view to prevent the items from being visually "moved".
        // That would be against the user intuition since the item has been taken from
        // the tableView and put on the cursor and is now dropped from the cursor back
        // into the table view.
        if isSameInstance {
            updateData(animate: true)
        }

        if target.above {
            delegate.insert(blocks: contents, before: target.id)
        } else {
            delegate.insert(blocks: contents, after: target.id)
        }

        updateData(animate: true)
        dragState.target = nil
    }

    func preview(forDropping item: UIDragItem, withDefault defaultPreview: UITargetedDragPreview) -> UITargetedDragPreview? {
        guard let interaction = item.localObject as? BlockEditorDragInteraction,
              let view = configureCell(for: interaction.content.id, useReusableCell: false) as? BlockEditorCell
        else { return defaultPreview }

        var center: CGPoint = .zero

        if let cell = cell(for: item) {
            center = cell.center
            view.frame = cell.frame
        }

        return UITargetedDragPreview(view: view, parameters: .init(), target: UIPreviewTarget(container: tableView, center: center))
    }

    func dropInteraction(_ interaction: UIDropInteraction, previewForDropping item: UIDragItem, withDefault defaultPreview: UITargetedDragPreview) -> UITargetedDragPreview? {
        // This function is not called when moving many (>5) items. Could be a bug, could be a performance optimization.
        // It seems to be a performance precaution, other apps have it too. Dealing with it by disabling the willAnimateDropWith animations.
        (item.localObject as? BlockEditorDragInteraction)?.dropPreviewAssociated = true
        return preview(forDropping: item, withDefault: defaultPreview)
    }

    func dropInteraction(_ interaction: UIDropInteraction, item: UIDragItem, willAnimateDropWith animator: UIDragAnimating) {
        guard let cell = cell(for: item), (item.localObject as? BlockEditorDragInteraction)?.dropPreviewAssociated ?? false else { return }

        animator.addAnimations {
            cell.isHidden = true
        }

        animator.addCompletion { _ in
            cell.isHidden = false
        }
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        dragState.dropActive = false
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        dragState.dropActive = true
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
        dragState.dropActive = false
        dragState.target = nil
    }
}
