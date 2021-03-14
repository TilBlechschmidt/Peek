//
//  FocusEngine.swift
//  Peek
//
//  Created by Til Blechschmidt on 07.03.21.
//

import Foundation
import Combine

class FocusEngine {
    private var anchor: UUID?

    @Published private(set) var cursor: UUID?
    @Published var selection = Set<UUID>()

    weak var delegate: FocusEngineDelegate?

    func toggle(_ item: UUID, deselectOther: Bool = false) {
        if selection.contains(item) {
            deselect(item)
        } else {
            select(item, deselectOther: deselectOther)
        }
    }

    func select(_ item: UUID, deselectOther: Bool = false) {
        if deselectOther {
            deselectAll()
        }

        selection.insert(item)
        cursor = item
        anchor = item
    }

    func selectAll() {
        guard let items = delegate?.allItems() else { return }
        selection = Set(items)
        anchor = items.first
        cursor = items.last
    }

    func deselect(_ item: UUID) {
        selection.remove(item)

        if anchor == item {
            cursor = nil
            anchor = nil
        } else if cursor == item {
            cursor = anchor
        }
    }

    func deselectAll() {
        selection.removeAll()
        anchor = nil
    }

    enum MoveDirection {
        case forward, backward
    }

    func moveCursor(_ direction: MoveDirection, retainSelection: Bool = false) {
        guard let delegate = delegate else { return }

        if !retainSelection && selection.count > 1 {
            // If we end a selection, move the cursor to the one end of the selection (depending on the direction)
            switch direction {
            case .forward:
                cursor = delegate.lastItem(of: selection)
            case .backward:
                cursor = delegate.firstItem(of: selection)
            }

            selection.removeAll()
            anchor = nil
        } else if retainSelection, let currentCursor = cursor, let currentAnchor = anchor {
            // TODO This needs an "anchor" and if we move back towards the anchor, it should move in single steps and deselect instead of select! Additionally, the anchor itself may never be deselected by this method.
            let shouldSelectMore = currentAnchor == currentCursor || delegate.direction(from: currentAnchor, to: currentCursor) == direction

            if shouldSelectMore {
                // Move the cursor through the selection in the requested direction until we hit a non-selected item
                if let newItem = moveToNextUnselectedItem(in: direction) {
                    selection.insert(newItem)
                }
            } else {
                if currentCursor != currentAnchor {
                    selection.remove(currentCursor)
                }

                switch direction {
                case .forward:
                    if let newCursor = delegate.item(after: currentCursor) {
                        cursor = newCursor
                    }
                case .backward:
                    if let newCursor = delegate.item(before: currentCursor) {
                        cursor = newCursor
                    }
                }
            }
        } else if !retainSelection, let currentCursor = cursor {
            // When we have no selection and are not altering it, just move the cursor
            switch direction {
            case .forward:
                if let newCursor = delegate.item(after: currentCursor) {
                    cursor = newCursor
                    anchor = newCursor
                }
            case .backward:
                if let newCursor = delegate.item(before: currentCursor) {
                    cursor = newCursor
                    anchor = newCursor
                }
            }
        } else {
            // If we are "creating" the cursor, start at either edge of the document
            switch direction {
            case .forward:
                cursor = delegate.firstItem()
                anchor = cursor
            case .backward:
                cursor = delegate.lastItem()
                anchor = cursor
            }
        }

        if !retainSelection, let cursor = cursor {
            selection = [cursor]
        }
    }

    private func moveToNextUnselectedItem(in direction: MoveDirection) -> UUID? {
        var newItem = cursor
        while let item = newItem {
            cursor = item

            if !selection.contains(item) {
                break
            }

            switch direction {
            case .forward:
                newItem = delegate?.item(after: item)
            case .backward:
                newItem = delegate?.item(before: item)
            }
        }

        return newItem
    }
}

protocol FocusEngineDelegate: class {
    /// Undefined behaviour when origin is equal to target.
    func direction(from origin: UUID, to target: UUID) -> FocusEngine.MoveDirection

    func firstItem() -> UUID?
    func lastItem() -> UUID?

    func firstItem(of set: Set<UUID>) -> UUID?
    func lastItem(of set: Set<UUID>) -> UUID?

    func item(after other: UUID) -> UUID?
    func item(before other: UUID) -> UUID?

    func allItems() -> [UUID]
}
