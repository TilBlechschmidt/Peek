//
//  LV+UIKeyCommands.swift
//  Peek
//
//  Created by Til Blechschmidt on 14.03.21.
//

import UIKit

extension NewBlockListViewController {
    override var keyCommands: [UIKeyCommand]? {
//        let commonCommands = [
////            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.command], action: #selector(focusFirstBlock)),
////            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [.command], action: #selector(focusLastBlock)),
//
//            // TODO Only active when the cursor is in a appropriate position or we are in non-editing mode
//            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.shift], action: #selector(extendSelectionUpwards)),
//            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [.shift], action: #selector(extendSelectionDownwards)),
//
//            // TODO Only active when the cursor is in a appropriate position or we are in non-editing mode
//            // TODO Make use of the horizontalCursorOffset when TextBlockCell comes into focus
//            UIKeyCommand(action: #selector(focusPreviousBlock), input: UIKeyCommand.inputUpArrow),
//            UIKeyCommand(action: #selector(focusNextBlock), input: UIKeyCommand.inputDownArrow),
////            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.shift, .command], action: #selector(extendSelectionToStartOfDocument)),
////            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [.shift, .command], action: #selector(extendSelectionToEndOfDocument)),
//        ]

        let commonCommands = [
            UIKeyCommand(action: #selector(createNewBlock), input: UIKeyCommand.inputReturn, discoverabilityTitle: "Add paragraph below"),
        ]

        if editorState.isEditingContent {
            return [
                UIKeyCommand(action: #selector(exitEditMode), input: UIKeyCommand.inputEscape, discoverabilityTitle: "Stop editing mode"),
            ] + commonCommands
        } else {
            return [
                UIKeyCommand(action: #selector(deleteSelection), input: UIKeyCommand.inputBackspace, discoverabilityTitle: "Delete selection"),
                UIKeyCommand(action: #selector(enterEditMode), input: " ", discoverabilityTitle: "Start editing mode"),
                UIKeyCommand(action: #selector(deselectAll), input: UIKeyCommand.inputEscape)
            ] + commonCommands
        }
    }

    @objc func enterEditMode() {
        editorState.isEditingContent = true
    }

    @objc func exitEditMode() {
        editorState.isEditingContent = false
    }

    @objc func deleteSelection() {
        for item in editorState.focusEngine.selection {
            editorState.focusEngine.deselect(item)
            editorState.blockManager.remove(item)
        }

        // TODO If the selection is empty, select the item above the deleted selection
    }

    @objc func createNewBlock() {
        if editorState.isEditingContent {
            guard let focusedCell = editorState.focusEngine.cursor, let indexPath = dataSource.indexPath(for: focusedCell), let cell = tableView.cellForRow(at: indexPath) as? BlockCell else {
                print("WARNING: Attempted to add block below cell that does not exit")
                return
            }

            // TODO If we are empty and you press RETURN, remove the admonition/blockquote
            let newBlock = UIBlock(admonition: cell.block.admonition, blockquote: cell.block.blockquote, content: cell.takeContentForNextBlock())
            editorState.blockManager.insert(newBlock, after: cell.block.id)
            editorState.focusEngine.select(newBlock.id, deselectOther: true)
        } else {
            // TODO Deal with selection and shiet
        }
    }

    @objc func focusPreviousBlock() {
        editorState.focusEngine.moveCursor(.backward)
    }

    @objc func focusNextBlock() {
        editorState.focusEngine.moveCursor(.forward)
    }

    @objc func extendSelectionUpwards() {
        editorState.focusEngine.moveCursor(.backward, retainSelection: true)
    }

    @objc func extendSelectionDownwards() {
        editorState.focusEngine.moveCursor(.forward, retainSelection: true)
    }

    @objc func deselectAll() {
        editorState.focusEngine.deselectAll()
    }
}
