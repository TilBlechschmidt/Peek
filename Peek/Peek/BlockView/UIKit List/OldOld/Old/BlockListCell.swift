//
//  BlockListCell.swift
//  Peek
//
//  Created by Til Blechschmidt on 02.03.21.
//

import UIKit
import SnapKit
import MarkdownKit
import Combine

class BlockListCell: UITableViewCell {
    private let blockView = UIBlockView()
    private var blockCancellables: [AnyCancellable] = []
    private var selectionCancellables: [AnyCancellable] = []

    weak var delegate: BlockListCellDelegate?
    weak var selection: SelectionState? {
        didSet {
            selectionCancellables.removeAll()
            selection?.$blockSelection
                .sink { [weak self] newSelection in
                    if let first = newSelection.first, first == self?.block.id {
                        self?.blockView.select(offset: self?.selection?.offset)
                    }
                }
                .store(in: &selectionCancellables)
        }
    }

    var connection: Connection {
        get {
            blockView.connection
        }
        set {
            blockView.connection = newValue
        }
    }

    var block: UIBlock! {
        didSet {
            blockCancellables.removeAll()

            block.$admonition
                .assign(to: \.admonition, on: blockView)
                .store(in: &blockCancellables)

            block.$blockquote
                .assign(to: \.blockquote, on: blockView)
                .store(in: &blockCancellables)

            block.$content
                .assign(to: \.content, on: blockView)
                .store(in: &blockCancellables)
        }
    }

    override func prepareForReuse() {
        blockCancellables.removeAll()
        selectionCancellables.removeAll()
        blockView.resignFirstResponder()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        blockView.delegate = self
        contentView.addSubview(blockView)
        blockView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.setNeedsLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BlockListCell: BlockInteractionDelegate {
    func blockRequestsDeletion() {
        selection?.offset = nil
        selection?.moveSelectionToBlock(before: block.id)
        delegate?.blockListCellRequestsDeletion(self)
    }

    func blockRequestsNewParagraph() {
        delegate?.blockListCellRequestsNewParagraph(self)
        self.selection?.offset = 0
        self.selection?.moveSelectionToBlock(after: self.block.id)
    }

    func blockDidChangeLayout() {
        delegate?.blockListCellDidChangeLayout(self)
    }
}

protocol BlockListCellDelegate: class {
    func blockListCellRequestsDeletion(_ cell: BlockListCell)
    func blockListCellRequestsNewParagraph(_ cell: BlockListCell)
    func blockListCellDidChangeLayout(_ cell: BlockListCell)
}
