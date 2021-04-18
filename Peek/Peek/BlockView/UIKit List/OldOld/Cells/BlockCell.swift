//
//  BlockList.swift
//  Peek
//
//  Created by Til Blechschmidt on 07.03.21.
//

import UIKit
import MarkdownKit
import Combine

class BlockCell: UITableViewCell {
    class var reuseIdentifier: String { "unknown-block" }

    weak var delegate: BlockCellDelegate?

    override var canBecomeFirstResponder: Bool {
        true
    }

    private var swipeGestureRecognizer: UISwipeGestureRecognizer!

    private var editorStateCancellables: [AnyCancellable] = []
    var editorState: EditorState! {
        didSet {
            editorStateChanged()
        }
    }

    override var canBecomeFocused: Bool {
        false
    }

    private var blockObservers: [AnyCancellable] = []
    var block: UIBlock! {
        didSet {
            editorStateChanged()

            blockObservers.removeAll()

            block.$content
                .sink { [weak self] in
                    self?.replaceContent(with: $0)
                }
                .store(in: &blockObservers)

            block.$admonition
                .sink { [weak self] in
                    self?.blockView.admonition = $0
                }
                .store(in: &blockObservers)

            block.$blockquote
                .sink { [weak self] in
                    self?.blockView.blockquote = $0
                }
                .store(in: &blockObservers)
        }
    }

    let blockView = BlockView()

    var blockContentView: UIView {
        blockView.contentView
    }

    func replaceContent(with newContent: Block.Content) {}

    func editorStateChanged() {
        editorStateCancellables.removeAll()

        editorState.$isEditingContent
            .sink { [weak self] isEditingContent in
                // TODO FocusEngine
//                self?.updateResponderState(cursor: self?.editorState.focusEngine.cursor)

                #if targetEnvironment(macCatalyst)
                self?.blockView.displaySelectionBox = false
                #else
                self?.blockView.displaySelectionBox = !isEditingContent
                self?.swipeGestureRecognizer.isEnabled = isEditingContent
                #endif
            }
            .store(in: &editorStateCancellables)

        // TODO FocusEngine
//        editorState.focusEngine.$selection
//            .sink { [weak self] selected in
//                self?.updateSelectionState(selection: selected)
//            }
//            .store(in: &editorStateCancellables)
//
//        editorState.focusEngine.$cursor
//            .sink { [weak self] cursor in
//                self?.updateResponderState(cursor: cursor)
//            }
//            .store(in: &editorStateCancellables)
    }

    override func prepareForReuse() {
        delegate = nil
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // TODO Replace this with a gesture recognizer that tracks the swipe and moves the view with the finger :)
        swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        swipeGestureRecognizer.direction = .left

        #if !targetEnvironment(macCatalyst)
        addGestureRecognizer(swipeGestureRecognizer)
        #endif

        backgroundColor = .clear
        selectedBackgroundView = UIView()
        contentView.addSubview(blockView)
        blockView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc func handleSwipeGesture() {
        delegate?.blockCellWasSwipedLeft(self)
    }

    private func updateSelectionState(selection: Set<UUID>) {
        if let id = block?.id {
            blockView.selected = selection.contains(id)
        }
    }

    private func updateResponderState(cursor: UUID?) {
        if let id = block?.id, let cursorID = cursor, cursorID == id {
            DispatchQueue.main.async {
                self.becomeFirstResponder()
            }
        } else if isFirstResponder {
            resignFirstResponder()
        }
    }
}

protocol BlockCellDelegate: class {
    func blockCellDidChangeLayout(_ blockCell: BlockCell, animate: Bool)
    func blockCellWasSwipedLeft(_ blockCell: BlockCell)

//    func delete(blockForCell: BlockCell)
//    func appendParagraph(after cell: BlockCell)
//
//    func focusBlock(before cell: BlockCell, at offset: CGFloat)
//    func focusBlock(after cell: BlockCell, at offset: CGFloat)
//
//    func focusFirstBlock()
//    func focusLastBlock()
//
//    func selectToFirstBlock(from cell: BlockCell)
//    func selectToLastBlock(from cell: BlockCell)
//
//    func selectToBlock(before cell: BlockCell)
//    func selectToBlock(after cell: BlockCell)
}
