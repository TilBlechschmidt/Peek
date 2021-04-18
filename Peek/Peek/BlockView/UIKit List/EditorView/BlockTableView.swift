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

    static let all: Self = [.escape, .selectAll, .focus, .moveCursorBackward, .moveCursorForward, .selectBackward, .selectForward, .moveToFirst, .moveToLast, .selectToFirst, .selectToLast, .moveCursorLeft, .moveCursorRight]
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
}

extension BlockTableView {
    func moveTo(block: UUID) {
        if case .focus = focusEngine.mode {
            focusEngine.focus(block)
        } else {
            focusEngine.deselectAll()
            focusEngine.select(block)
        }
    }
}
