//
//  BlockCell+UIKeyCommand.swift
//  Peek
//
//  Created by Til Blechschmidt on 14.03.21.
//

import UIKit
import MarkdownKit

extension BlockCell {
    var shouldNavigateToNextBlock: Bool {
        true
    }

    var shouldNavigateToPreviousBlock: Bool {
        true
    }

    var shouldDeleteSelf: Bool {
        true
    }

    /// Removes any content after the sub-block cursor from this block and returns it for insertion into the next block
    func takeContentForNextBlock() -> Block.Content {
        .text("")
    }

    override var keyCommands: [UIKeyCommand]? {
        var commands: [UIKeyCommand] = []

        // TODO Move line up/down (one/all)

        if shouldDeleteSelf {
            commands += [
            ]
        }

        if shouldNavigateToPreviousBlock {
            commands += [
                UIKeyCommand(action: #selector(focusPreviousBlock), input: UIKeyCommand.inputUpArrow),
                UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.command], action: #selector(focusFirstBlock)),
                UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.shift], action: #selector(extendSelectionUpwards)),
                UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.shift, .command], action: #selector(extendSelectionToStartOfDocument)),
            ]
        }

        if shouldNavigateToNextBlock {
            commands += [
                UIKeyCommand(action: #selector(focusNextBlock), input: UIKeyCommand.inputDownArrow),
                UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.command], action: #selector(focusLastBlock)),
                UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.shift], action: #selector(extendSelectionDownwards)),
                UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [.shift, .command], action: #selector(extendSelectionToEndOfDocument)),
            ]
        }

        return commands
    }

    @objc func deleteSelf() {
        print("DELETE")
    }

    // MARK: Backwards navigation / selection

    @objc func focusPreviousBlock() {
        // TODO
    }

    @objc func focusFirstBlock() {
        // TODO
    }

    @objc func extendSelectionUpwards() {
        // TODO
    }

    @objc func extendSelectionToStartOfDocument() {
        // TODO
    }

    // MARK: Forwards navigation / selection

    @objc func focusNextBlock() {
        // TODO
    }

    @objc func focusLastBlock() {
        // TODO
    }

    @objc func extendSelectionDownwards() {
        // TODO
    }

    @objc func extendSelectionToEndOfDocument() {
        // TODO
    }
}
