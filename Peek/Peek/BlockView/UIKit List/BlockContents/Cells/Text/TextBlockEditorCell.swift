//
//  TextBlockEditorCell.swift
//  Peek
//
//  Created by Til Blechschmidt on 18.04.21.
//

import UIKit
import Combine

class TextBlockEditorCell: BlockEditorCell {
    static var identifier = "ContentB"

    private let textView = BlockTextView(textStorage: NSTextStorage(string: "Hello world"))

    private var keyboardHideCancellable: AnyCancellable!
    private var contentCancellable: AnyCancellable!

    weak var content: TextContentBlock! {
        didSet {
            contentCancellable = content.$text.sink { [weak self] in
                guard let self = self else { return }

                let selection = self.textView.selectedRange
                self.textView.text = $0
                self.textView.selectedRange = selection
            }
        }
    }

    var selection: NSRange {
        textView.selectedRange
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // Keyboard notifications are unreliable and didHide is sometimes fired even when the keyboard stays present.
        // In these cases, didShow is fired milliseconds after (e.g. when switching from one responder to another under certain circumstances).
        // To circumvent all the heaps of issues this causes, we are delaying the reaction. In the time that passes,
        //  the FocusEngine has processed the focus change and thus the guard statement will cancel the invalid deselect action.
        //
        // The filter ensures that only instances that were actually focused at the time the event is fired receive the delayed notification.
        keyboardHideCancellable = NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
            .filter { [weak self] _ in self.flatMap { $0.focusEngine.mode == .focus(item: $0.blockID) } ?? false }
            .delay(for: 0.1, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self, self.focusEngine.mode == .focus(item: self.blockID) else { return }
                self.focusEngine.deselect(self.blockID)
            }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var textContentView: UIView {
        textView
    }

    override var containsTrailingContent: Bool {
        !textView.caretIsAtEnd
    }

    override var capturedKeyCommands: BlockEditorKeyCommands {
        var capturedCommands: BlockEditorKeyCommands = []

        if !(textView.caretIsAtBeginning || textView.caretIsOnFirstLine) {
            capturedCommands.insert(.moveCursorBackward)
            capturedCommands.insert(.selectBackward)
        }

        if !textView.caretIsAtBeginning {
            capturedCommands.insert(.selectToFirst)
            capturedCommands.insert(.moveCursorLeft)
        }

        if !(textView.caretIsAtEnd || textView.caretIsOnLastLine) {
            capturedCommands.insert(.moveCursorForward)
            capturedCommands.insert(.selectForward)
        }

        if !textView.caretIsAtEnd {
            capturedCommands.insert(.selectToLast)
            capturedCommands.insert(.moveCursorRight)
        }

        if !(textView.text.isEmpty || (textView.caretIsAtBeginning && textView.selectedRange.length == 0)) {
            capturedCommands.insert(.delete)
        }

        return capturedCommands
    }

    override func configureContent(in contentView: UIView) {
        textView.delegate = self
        textView.keyPressDelegate = self
        contentView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }

    override func focusModeDidChange(active: Bool, mode: FocusEngine.Mode) {
        if case .none = mode, focusEngine.defaultToFocusMode {
            setTextEditingState(true)
        } else {
            setTextEditingState(active)
        }
    }

    override func focusStateDidChange(focused: Bool) {
        if focused {
            textView.becomeFirstResponder()

            var point = focusEngine.caret

            // Set the Y coordinate based on where the cursor came from:
            //  With the cursor moving down, set the Y to the first line
            //  With the cursor moving up, set the Y to the last line
            //  With no movement, snap to the closest line (e.g. when focusing by clicking the padding)
            switch focusEngine.lastMoveDirection {
            case .forward,
                 nil where point.y < 0:
                point.y = 0
            case .backward,
                 nil where point.y > textView.lastLineY:
                point.y = textView.lastLineY
            case .none:
                break
            }

            let location = textView.textLocation(for: point)
            textView.selectedRange = .init(location: location, length: 0)
        } else {
            textView.resignFirstResponder()
        }
    }

    private func setTextEditingState(_ editing: Bool) {
        textView.isUserInteractionEnabled = editing
        textView.isSelectable = editing
        textView.isEditable = editing
    }
}

extension TextBlockEditorCell: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        cellWasExternallyFocused()
    }

    func textViewDidChange(_ textView: UITextView) {
        // TODO Check if the height actually changed
        cellChangedLayoutHeight()

        content?.text = textView.text
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        // TODO When moving over from another view, ignore the first selection change
        //      This prevents "drift" when moving the cursor up and down repeatedly
        focusEngine.caret = self.textView.selectedGlyphLocation
    }
}

extension TextBlockEditorCell: BlockTextViewKeyPressDelegate {
    func shouldTextViewCaptureNewline() -> Bool {
        true
    }

    func shouldTextViewCaptureBackspace() -> Bool {
        !capturedKeyCommands.contains(.delete)
    }

    // TODO The calls below do not honor modifiers (in fact they completely ignore them) which allows e.g. SHIFT + RETURN
    //      Figure out if this is actually desirable ;)

    func blockTextViewDidCaptureNewline() {
        (viewController.tableView as? BlockTableView)?.insertBelow()
    }

    func blockTextViewDidCaptureBackspace() {
        (viewController.tableView as? BlockTableView)?.deleteBlock()
    }
}
