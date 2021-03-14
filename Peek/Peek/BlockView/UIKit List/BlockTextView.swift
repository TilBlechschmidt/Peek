//
//  BlockTextView.swift
//  Peek
//
//  Created by Til Blechschmidt on 07.03.21.
//

import UIKit

protocol BlockTextViewDelegate: class {
    func deleteParagraph()
    func appendParagraphBelow()

//    func goToPreviousParagraph(at offset: CGFloat)
//    func goToNextParagraph(at offset: CGFloat)
//
//    func goToBeginningOfDocument()
//    func goToEndOfDocument()
//
//    func selectToBeginningOfDocument()
//    func selectToEndOfDocument()
//
//    func selectThisAndPreviousBlock()
//    func selectThisAndNextBlock()
}

class BlockTextView: UITextView {
    private var shifted: Bool = false
    private var command: Bool = false

    weak var inlineDelegate: BlockTextViewDelegate?

    var selectedGlyphIndex: Int {
        // TODO Handle empty content
        let characterIndex = selectedRange.location == text.count ? selectedRange.location - 1 : selectedRange.location
        return layoutManager.glyphIndexForCharacter(at: characterIndex)
    }

    var selectedLineRect: CGRect {
        layoutManager.lineFragmentUsedRect(forGlyphAt: selectedGlyphIndex, effectiveRange: nil)
    }

    var selectedGlyphLocation: CGPoint {
        text.isEmpty ? CGPoint(x: 0, y: 0) : layoutManager.location(forGlyphAt: selectedGlyphIndex)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
//        print("press")
        guard let key = presses.first?.key else { return }

//        print(command, shifted)

        switch key.keyCode {
        case .keyboardLeftShift, .keyboardRightShift:
            shifted = true
        case .keyboardLeftGUI, .keyboardRightGUI:
            command = true
//        case .keyboardUpArrow:
//            if command && !shifted {
//                inlineDelegate?.goToBeginningOfDocument()
//            } else if text.isEmpty || selectedLineRect.minY == 0 {
//                if shifted && command {
//                    inlineDelegate?.selectToBeginningOfDocument()
//                } else if shifted {
//                    print("Select this and previous block")
//                    return
//                } else {
//                    inlineDelegate?.goToPreviousParagraph(at: selectedGlyphLocation.x)
//                }
//            }
//        case .keyboardDownArrow:
//            if command && !shifted {
//                inlineDelegate?.goToEndOfDocument()
//            } else if text.isEmpty || selectedLineRect.maxY == textContainer.size.height {
//                if shifted && command {
//                    inlineDelegate?.selectToEndOfDocument()
//                    return
//                } else if shifted {
//                    print("Select this and next block")
//                    return
//                } else {
//                    inlineDelegate?.goToNextParagraph(at: selectedGlyphLocation.x)
//                }
//            }
        default:
            ()
        }

        super.pressesBegan(presses, with: event)
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)

        guard let key = presses.first?.key else { return }

        switch key.keyCode {
        case .keyboardLeftShift, .keyboardRightShift:
            shifted = false
        case .keyboardLeftGUI, .keyboardRightGUI:
            command = false
        default:
            return
        }
    }

//    override func insertText(_ text: String) {
//        // TODO Allow some method of adding softbreaks on iOS
//        //      For example when the last character in a line is a \ and you return
//        //      then remove the backslash and do a softbreak. Although that is technically
//        //      speaking a hardbreak in Markdown. Figure something out future self :D
//        if !shifted && text.count == 1, let first = text.first, first.isNewline {
//            inlineDelegate?.appendParagraphBelow()
//        } else {
//            super.insertText(text)
//        }
//    }
//
//    override func deleteBackward() {
//        if self.text.isEmpty {
//            inlineDelegate?.deleteParagraph()
//        }
//
//        super.deleteBackward()
//    }
}
