//
//  BlockManager+BlockEditorDelegate.swift
//  Peek
//
//  Created by Til Blechschmidt on 18.04.21.
//

import UIKit

extension BlockManager: BlockEditorDelegate {
    // MARK: - Content list
    func content(for id: UUID) -> ContentBlock? {
        guard let index = index(of: id) else { return nil }
        return blocks.value[index]
    }

    // MARK: - Cell management
    func registerCells(with tableView: UITableView) {
//        tableView.register(ContentCellA.self, forCellReuseIdentifier: ContentCellA.identifier)
        tableView.register(TextBlockEditorCell.self, forCellReuseIdentifier: TextBlockEditorCell.identifier)
    }

    func cellIdentifier(for block: UUID) -> String {
//        let index = blockManager.allItems().firstIndex(of: block) ?? 0
//        return index % 2 == 0 ? ContentCellA.identifier : ContentCellB.identifier
        return TextBlockEditorCell.identifier
    }

    func configure(cell: BlockEditorCell, for block: UUID) {
//        if let cell = cell as? ContentCellA {
//            cell.textLabel?.text = "ContentA \(block)"
//        } else
        if let cell = cell as? TextBlockEditorCell, let content = content(for: block) as? TextContentBlock {
            cell.content = content
        }
    }

    // MARK: - Content modification
    func newBlock(forInsertionAfter id: UUID) -> ContentBlock {
        TextContentBlock(text: "")
    }

    func insert(_ block: ContentBlock, at index: Int) {
        guard !manages(block.id) else { return }
        blocks.value.insert(block, at: index)
    }

    func insert(_ block: ContentBlock, before id: UUID) {
        guard !manages(block.id), let index = index(of: id) else { return }
        blocks.value.insert(block, at: index)
    }

    func insert(_ block: ContentBlock, after id: UUID) {
        guard !manages(block.id), let index = index(of: id) else { return }
        blocks.value.insert(block, at: index + 1)
    }

    func append(_ block: ContentBlock) {
        guard !manages(block.id) else { return }
        blocks.value.append(block)
    }

    func remove(_ id: UUID) {
        guard let index = index(of: id) else { return }
        blocks.value.remove(at: index)
    }

    func removeAll(in collection: [UUID]) {
        blocks.value = blocks.value.filter({ !collection.contains($0.id) })
    }
}
