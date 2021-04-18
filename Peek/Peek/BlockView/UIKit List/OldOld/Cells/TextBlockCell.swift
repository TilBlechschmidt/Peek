//
//  TextBlockCell.swift
//  Peek
//
//  Created by Til Blechschmidt on 07.03.21.
//

import UIKit
import MarkdownKit
import SnapKit
import Combine

class TextBlockCell: BlockCell {
    static override var reuseIdentifier: String { "text-block" }

    private let textView = BlockTextView()
    private var editorStateCancellable: AnyCancellable?
    private var commitTimer: Timer?

    override func becomeFirstResponder() -> Bool {
        textView.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        textView.resignFirstResponder()
    }

    override var isFirstResponder: Bool {
        textView.isFirstResponder
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        textView.font = .systemFont(ofSize: 14)
        textView.delegate = self
        textView.inlineDelegate = self

        textView.isScrollEnabled = false
        textView.alwaysBounceVertical = false
        textView.isUserInteractionEnabled = true

        textView.contentInset = .zero
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0

        textView.backgroundColor = .clear
        blockContentView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func editorStateChanged() {
        super.editorStateChanged()
        
        editorStateCancellable = editorState.$isEditingContent.sink { [weak self] isEditingContent in
            self?.setTextEditingState(isEditingContent)
        }
    }

    override func replaceContent(with newContent: Block.Content) {
        guard case .text(let text) = newContent else {
            // This is sometimes called when a cell changes its type
            return
        }

        textView.text = text
    }

    func setTextEditingState(_ editing: Bool) {
        contentView.isUserInteractionEnabled = editing
        textView.isUserInteractionEnabled = editing
        textView.isEditable = editing
        textView.isSelectable = editing
    }
}

extension TextBlockCell {
    func contentChanged() {
        commitTimer?.invalidate()
        commitTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(commitChanges), userInfo: nil, repeats: false)
        commitTimer?.tolerance = 0.5
    }

    @objc func commitChanges() {
        block.content = .text(textView.text)
    }
}

extension TextBlockCell: UITextViewDelegate, BlockTextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        contentChanged()
        delegate?.blockCellDidChangeLayout(self, animate: true)

        if let blockTextView = textView as? BlockTextView {
            editorState.horizontalCharacterOffset = blockTextView.selectedGlyphLocation.x
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        commitChanges()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        if let blockTextView = textView as? BlockTextView {
            editorState.horizontalCharacterOffset = blockTextView.selectedGlyphLocation.x
        }
    }

    func deleteParagraph() {
        // TODO
    }

    func appendParagraphBelow() {
        // TODO
    }
}
