//
//  BlockTextView.swift
//  Peek
//
//  Created by Til Blechschmidt on 15.04.21.
//

import UIKit

protocol BlockTextViewKeyPressDelegate: class {
    func shouldTextViewCaptureNewline() -> Bool
    func shouldTextViewCaptureBackspace() -> Bool

    func blockTextViewDidCaptureNewline()
    func blockTextViewDidCaptureBackspace()
}

class BlockTextView: UITextView {
    weak var keyPressDelegate: BlockTextViewKeyPressDelegate?

    init(textStorage: NSTextStorage) {
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer(size: .zero)
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)
        textStorage.addLayoutManager(layoutManager)

        super.init(frame: .zero, textContainer: container)

        assert(self.textStorage == textStorage)

        textColor = .label
        backgroundColor = .clear

        font = UIFont.preferredFont(forTextStyle: .body)

        isScrollEnabled = false
        alwaysBounceVertical = false
        isUserInteractionEnabled = true

        contentInset = .zero
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0

        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BlockTextView {
    override func insertText(_ text: String) {
        // Ask the delegate whether it wants to capture the newline press or not
        if text.count == 1, text.first?.isNewline ?? false, let delegate = keyPressDelegate, delegate.shouldTextViewCaptureNewline() {
            delegate.blockTextViewDidCaptureNewline()
        } else {
            super.insertText(text)
        }
    }

    override func deleteBackward() {
        if let delegate = keyPressDelegate, delegate.shouldTextViewCaptureBackspace() {
            delegate.blockTextViewDidCaptureBackspace()
        } else {
            super.deleteBackward()
        }
    }
}

extension BlockTextView {
    private var selectedGlyphIndex: Int {
        // TODO Handle empty content
        let characterIndex = selectedRange.location == text.count ? selectedRange.location - 1 : selectedRange.location
        return layoutManager.glyphIndexForCharacter(at: characterIndex)
    }

    private var selectedLineRect: CGRect {
        text.isEmpty ? .zero : layoutManager.lineFragmentUsedRect(forGlyphAt: selectedGlyphIndex, effectiveRange: nil)
    }

    var selectedGlyphLocation: CGPoint {
        guard !text.isEmpty else { return CGPoint(x: 0, y: 0) }

        let lineRect = selectedLineRect
        var location = layoutManager.location(forGlyphAt: selectedGlyphIndex)
        location.y = lineRect.midY

        // Use the position after the last glyph if we are at the end
        if selectedRange.location == text.count {
            location.x = lineRect.maxX
        }

        // TODO If cursor is at the end of a line, the selectedGlyph is actually on the next line
        //      This causes issues, fix it :D
        //      (e.g. when moving the cursor down from the 2nd line in a three line block
        //              and caretIsOnLastLine returns true instead of false the cursor moves to the next block)

        return location
    }

    var caretIsAtBeginning: Bool {
        text.isEmpty || selectedRange.lowerBound == 0
    }

    var caretIsAtEnd: Bool {
        text.isEmpty || selectedRange.upperBound == text.count
    }

    var caretIsOnFirstLine: Bool {
        text.isEmpty || selectedLineRect.minY == 0
    }

    var caretIsOnLastLine: Bool {
        guard !text.isEmpty else { return true }

        return selectedLineRect.midY == lastLineY
    }

    var lastLineY: CGFloat {
        guard !text.isEmpty else { return 0 }

        let lastGlyphIndex = layoutManager.glyphRange(for: textContainer).upperBound - 1
        return layoutManager.lineFragmentUsedRect(forGlyphAt: lastGlyphIndex, effectiveRange: nil).midY
    }

    func textLocation(for point: CGPoint) -> Int {
        let clampedPoint = CGPoint(x: min(point.x, bounds.width), y: min(point.y, bounds.height))

        var fraction: CGFloat = 0.0
        let index = layoutManager.characterIndex(for: clampedPoint, in: textContainer, fractionOfDistanceBetweenInsertionPoints: &fraction)

        return index + Int(round(fraction))
    }
}
