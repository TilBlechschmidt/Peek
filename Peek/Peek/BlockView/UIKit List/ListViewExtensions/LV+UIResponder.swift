//
//  LV+UIResponder.swift
//  Peek
//
//  Created by Til Blechschmidt on 14.03.21.
//

import UIKit

extension NewBlockListViewController {
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)

        guard let key = presses.first?.key else { return }

        switch key.keyCode {
        case .keyboardLeftShift, .keyboardRightShift:
            activeModifierFlags.insert(.shift)
        case .keyboardLeftGUI, .keyboardRightGUI:
            activeModifierFlags.insert(.command)
        default:
            ()
        }
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        handleModifierRelease(presses)
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        handleModifierRelease(presses)
    }

    private func handleModifierRelease(_ presses: Set<UIPress>) {
        guard let key = presses.first?.key else { return }

        // TODO This breaks when you press two modifiers keys of the same type and release one
        switch key.keyCode {
        case .keyboardLeftShift, .keyboardRightShift:
            activeModifierFlags.remove(.shift)
        case .keyboardLeftGUI, .keyboardRightGUI:
            activeModifierFlags.remove(.command)
        default:
            ()
        }
    }
}
