//
//  EditorView+Drag.swift
//  Peek
//
//  Created by Til Blechschmidt on 19.04.21.
//

import UIKit

class BlockEditorDragInteraction {
    private let content: ContentBlock
    private let sourceDelegate: BlockEditorDelegate
    private var committed: Bool = false

    internal init(content: ContentBlock, sourceDelegate: BlockEditorDelegate) {
        self.content = content
        self.sourceDelegate = sourceDelegate
    }

    func commit() -> ContentBlock {
        guard !committed else { fatalError("Attempted to commit an already commited interaction") }

        committed = true
        sourceDelegate.remove(content.id)

        return content
    }
}

extension BlockEditorViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let delegate = delegate, let id = dataSource.itemIdentifier(for: indexPath), let content = delegate.content(for: id) else { return [] }

        let provider = content.serializeForDrag()
        let item = UIDragItem(itemProvider: provider)
        let blockItem = BlockEditorDragInteraction(content: content, sourceDelegate: delegate)
        item.localObject = blockItem

        return [item]
    }

    func tableView(_ tableView: UITableView, dragSessionAllowsMoveOperation session: UIDragSession) -> Bool {
        true
    }
}
