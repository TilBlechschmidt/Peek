//
//  BlockTableView.swift
//  Peek
//
//  Created by Til Blechschmidt on 14.04.21.
//

import UIKit

struct BlockEditorKeyCommands: OptionSet {
    let rawValue: Int

    static let escape               = Self(rawValue: 1 << 0)
    static let selectAll            = Self(rawValue: 1 << 1)
    static let focus                = Self(rawValue: 1 << 2)

    static let moveCursorBackward   = Self(rawValue: 1 << 3)
    static let moveCursorForward    = Self(rawValue: 1 << 4)

    static let selectBackward       = Self(rawValue: 1 << 5)
    static let selectForward        = Self(rawValue: 1 << 6)

    static let moveToFirst          = Self(rawValue: 1 << 7)
    static let moveToLast           = Self(rawValue: 1 << 8)

    static let selectToFirst        = Self(rawValue: 1 << 9)
    static let selectToLast         = Self(rawValue: 1 << 10)

    static let moveCursorLeft       = Self(rawValue: 1 << 11)
    static let moveCursorRight      = Self(rawValue: 1 << 12)

    static let delete               = Self(rawValue: 1 << 13)
    static let insertBelow          = Self(rawValue: 1 << 14)

    static let all: Self = [.escape, .selectAll, .focus, .moveCursorBackward, .moveCursorForward, .selectBackward, .selectForward, .moveToFirst, .moveToLast, .selectToFirst, .selectToLast, .moveCursorLeft, .moveCursorRight, .delete, .insertBelow]
    static let none: Self = []
}

class BlockTableView: UITableView {
    weak var focusEngine: FocusEngine!
    weak var viewController: BlockEditorViewController!

    override var keyCommands: [UIKeyCommand]? {
        var keyCommands: BlockEditorKeyCommands = .all

        if case .focus(let block) = focusEngine.mode {
            keyCommands.subtract(.focus)

            let activeCell = viewController.cell(for: block)
            if let capturedKeyCommands = activeCell?.capturedKeyCommands {
                keyCommands.subtract(capturedKeyCommands)
            }
        }

        var activeKeyCommands: [UIKeyCommand] = []

        if keyCommands.contains(.escape) {
            activeKeyCommands.append(UIKeyCommand(action: #selector(escape), input: UIKeyCommand.inputEscape))
        }

        if keyCommands.contains(.selectAll) {
            activeKeyCommands.append(UIKeyCommand(input: "a", modifierFlags: .command, action: #selector(selectAllBlocks)))
        }

        if keyCommands.contains(.focus) {
            activeKeyCommands.append(UIKeyCommand(action: #selector(enterFocusMode), input: " "))
        }

        if keyCommands.contains(.moveCursorBackward) {
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(moveUp)))
        }

        if keyCommands.contains(.moveCursorForward) {
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(moveDown)))
        }

        if keyCommands.contains(.selectBackward) {
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: .shift, action: #selector(selectUp)))
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.shift, .alternate], action: #selector(selectUp)))
        }

        if keyCommands.contains(.selectForward) {
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: .shift, action: #selector(selectDown)))
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [.shift, .alternate], action: #selector(selectDown)))
        }

        if keyCommands.contains(.moveToFirst) {
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: .command, action: #selector(moveToFirst)))
        }

        if keyCommands.contains(.moveToLast) {
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: .command, action: #selector(moveToLast)))
        }

        if keyCommands.contains(.selectToFirst) {
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.shift, .command], action: #selector(selectToFirst)))
        }

        if keyCommands.contains(.selectToLast) {
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [.shift, .command], action: #selector(selectToLast)))
        }

        if keyCommands.contains(.moveCursorLeft) {
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(moveCursorLeft)))
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [.alternate], action: #selector(moveCursorLeft)))
            // TODO Potentially allow Shift(+Alternate)+Left = selectUp
        }

        if keyCommands.contains(.moveCursorRight) {
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(moveCursorRight)))
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [.alternate], action: #selector(moveCursorRight)))
            // TODO Potentially allow Shift(+Alternate)+Right = selectDown
        }

        // TODO These key commands are not triggered by the software keyboard when focused on a text input :(
        //      We have to place an overide into the TextBlock to catch those ...
        if keyCommands.contains(.delete) {
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputBackspace, modifierFlags: [], action: #selector(deleteBlock)))
        }

        if keyCommands.contains(.insertBelow) {
            activeKeyCommands.append(UIKeyCommand(input: UIKeyCommand.inputReturn, modifierFlags: [], action: #selector(insertBelow)))
        }

        return activeKeyCommands
    }

    @objc func selectAllBlocks() {
        focusEngine.selectAll()
    }

    @objc func escape() {
        if case .focus(let item) = focusEngine.mode, !focusEngine.defaultToFocusMode {
            focusEngine.select(item, ignoreFocus: true)
        } else {
            focusEngine.deselectAll()
        }
    }

    @objc func enterFocusMode() {
        focusEngine.enterFocusMode()
    }

    @objc func moveUp() {
        focusEngine.moveCursor(.backward, retainSelection: false)
    }

    @objc func moveDown() {
        focusEngine.moveCursor(.forward, retainSelection: false)
    }

    @objc func selectUp() {
        focusEngine.moveCursor(.backward, retainSelection: true)
    }

    @objc func selectDown() {
        focusEngine.moveCursor(.forward, retainSelection: true)
    }

    @objc func moveToFirst() {
        guard let first = focusEngine.delegate?.firstItem() else { return }
        focusEngine.caret = .zero
        moveTo(block: first)
    }

    @objc func moveToLast() {
        guard let last = focusEngine.delegate?.lastItem() else { return }
        focusEngine.caret = .infinity
        moveTo(block: last)
    }

    @objc func selectToFirst() {
        guard let first = focusEngine.delegate?.firstItem() else { return }
        focusEngine.moveCursor(to: first)
    }

    @objc func selectToLast() {
        guard let last = focusEngine.delegate?.lastItem() else { return }
        focusEngine.moveCursor(to: last)
    }

    @objc func moveCursorLeft() {
        focusEngine.caret = .infinity
        focusEngine.moveCursor(.backward)
    }

    @objc func moveCursorRight() {
        focusEngine.caret = .zero
        focusEngine.moveCursor(.forward)
    }

    @objc func deleteBlock() {
        if case .focus(let focusedItem) = focusEngine.mode, let activeCell = viewController.cell(for: focusedItem), activeCell.containsTrailingContent {
            guard let previousItem = focusEngine.delegate?.item(before: focusedItem),
                  let activeContent = viewController.delegate?.content(for: focusedItem),
                  let previousContent = viewController.delegate?.content(for: previousItem),
                  previousContent.canIntegrate(content: activeContent)
            else { return }

            viewController.delegate?.remove(focusedItem)

            focusEngine.caret = .infinity
            focusEngine.focus(previousItem)

            previousContent.integrate(content: activeContent)
        } else {
            // TODO The deselection logic really should be handled by the focusEngine.
            //      However, we need to know of the deletion before it happens to make calls to the delegate.
            //      Figure out a way to integrate this cleanly into the focusEngine.
            //  Idea: delegate allows focusEngine to observe a "willDeleteItems" publisher and react prior to the deletion
            let firstItemInSelection = focusEngine.delegate?.firstItem(of: Set(focusEngine.selected))
            let itemBeforeSelection = firstItemInSelection.flatMap { focusEngine.delegate?.item(before: $0) }

            viewController.delegate?.removeAll(in: focusEngine.selected)

            var wasInFocusMode = false
            if case .focus = focusEngine.mode {
                wasInFocusMode = true
            }

            focusEngine.deselectAll()
            if let newlySelectedItem = itemBeforeSelection {
                if wasInFocusMode {
                    focusEngine.caret = .infinity
                    focusEngine.focus(newlySelectedItem)
                } else {
                    focusEngine.select(newlySelectedItem, ignoreFocus: true)
                }
            }
        }
    }

    @objc func insertBelow() {
        if case .focus(let focusedItem) = focusEngine.mode, let activeCell = viewController.cell(for: focusedItem), activeCell.containsTrailingContent, let delegate = viewController.delegate, let activeContent = delegate.content(for: focusedItem) {
            let newContent = activeContent.extractTrailingContent(activeCell) ?? delegate.newBlock(forInsertionAfter: focusedItem)
            delegate.insert(newContent, after: focusedItem)

            DispatchQueue.main.async {
                self.focusEngine.caret = .zero
                self.focusEngine.focus(newContent.id)
            }
        } else if let cursor = focusEngine.cursorPosition ?? focusEngine.delegate?.lastItem(), let delegate = viewController.delegate {
            let block = delegate.newBlock(forInsertionAfter: cursor)
            delegate.insert(block, after: cursor)

            DispatchQueue.main.async {
                self.focusEngine.focus(block.id)
            }
        }
    }
}

extension BlockTableView {
    private func moveTo(block: UUID) {
        if case .focus = focusEngine.mode {
            focusEngine.focus(block)
        } else {
            focusEngine.deselectAll()
            focusEngine.select(block)
        }
    }
}

extension BlockEditorViewController {
    override var canBecomeFirstResponder: Bool {
        false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("TOUCHES BEGAN 2")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("TOUCHES ENDED 2")
    }
}
