//
//  EditorView+Drag.swift
//  Peek
//
//  Created by Til Blechschmidt on 19.04.21.
//

import UIKit

class BlockEditorDragInteraction {
    let content: ContentBlock
    let sourceDelegateInstance: UUID
    var destinationDelegateInstance: UUID?
    var dropPreviewAssociated: Bool

    internal init(content: ContentBlock, sourceDelegateInstance: UUID, dropPreviewAssociated: Bool = false) {
        self.content = content
        self.sourceDelegateInstance = sourceDelegateInstance
        self.dropPreviewAssociated = dropPreviewAssociated
    }
}

extension BlockEditorViewController: UIDragInteractionDelegate {
    func configureDragInteraction() {
        tableView.addInteraction(UIDragInteraction(delegate: self))
    }

    func dragItem(for blockID: UUID) -> UIDragItem? {
        guard let delegate = delegate, let content = delegate.content(for: blockID) else { return nil }

        let item = UIDragItem(itemProvider: content.serializeForDrag())
        let interaction = BlockEditorDragInteraction(content: content, sourceDelegateInstance: delegate.instance)
        item.localObject = interaction

        return item
    }

    func blockIDForTouch(at location: CGPoint) -> UUID? {
        tableView.indexPathForRow(at: location).flatMap { dataSource.itemIdentifier(for: $0) }
    }

    func cell(for item: UIDragItem) -> BlockEditorCell? {
        guard let interaction = item.localObject as? BlockEditorDragInteraction else { return nil }
        return cell(for: interaction.content.id)
    }

    func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: UIDragSession) {
        dragState.dragActive = true
        focusEngine.deselectAll()
    }

    func dragInteraction(_ interaction: UIDragInteraction, session: UIDragSession, didEndWith operation: UIDropOperation) {
        dragState.dragActive = false
        dragState.participatingBlocks = []
    }

    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        let location = session.location(in: tableView)
        var participatingBlocks = focusEngine.selected
            .sorted {
                focusEngine.delegate?.direction(from: $0, to: $1) == .forward
            }

        if let blockID = blockIDForTouch(at: location), !focusEngine.selected.contains(blockID) {
            participatingBlocks = [blockID]
        }

        return participatingBlocks.compactMap { dragItem(for: $0) }
    }

    func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
        guard let cell = cell(for: item) else { return nil }
        return UITargetedDragPreview(view: cell)
    }

    func dragInteraction(_ interaction: UIDragInteraction, previewForCancelling item: UIDragItem, withDefault defaultPreview: UITargetedDragPreview) -> UITargetedDragPreview? {
        preview(forDropping: item, withDefault: defaultPreview)
    }

    func dragInteraction(_ interaction: UIDragInteraction, willAnimateLiftWith animator: UIDragAnimating, session: UIDragSession) {
        let cells = session.items.lazy.compactMap { self.cell(for: $0) }

        animator.addAnimations {
            cells.forEach {
                $0.selectionTypeDidChange(to: .incidental)
            }
        }

        animator.addCompletion { [unowned self] _ in
            cells.forEach {
                $0.selectionTypeDidChange(to: .none)
            }

            session.items.lazy
                .compactMap { $0.localObject as? BlockEditorDragInteraction }
                .map { $0.content.id }
                .forEach {
                    dragState.participatingBlocks.insert($0)
                }
        }
    }

    func dragInteraction(_ interaction: UIDragInteraction, sessionAllowsMoveOperation session: UIDragSession) -> Bool {
        true
    }

    func dragInteraction(_ interaction: UIDragInteraction, prefersFullSizePreviewsFor session: UIDragSession) -> Bool {
        true
    }

    func dragInteraction(_ interaction: UIDragInteraction, session: UIDragSession, willEndWith operation: UIDropOperation) {
        guard let delegate = delegate else { return }

        if operation == .move {
            for item in session.items {
                guard let interaction = item.localObject as? BlockEditorDragInteraction,
                      interaction.sourceDelegateInstance != interaction.destinationDelegateInstance
                else { continue }
                
                delegate.remove(interaction.content.id)
            }
        }
    }
}
