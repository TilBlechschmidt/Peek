//
//  FocusEngine.swift
//  Peek
//
//  Created by Til Blechschmidt on 07.03.21.
//

import Foundation
import Combine
import CoreGraphics

class FocusEngine {
    enum Mode: Equatable {
        case none
        case focus(item: UUID)

        /// A selection is represented by a range that is spanned by the cursor and anchor.
        /// In addition, non-connected incidentals may exist which are disconnected from the selection
        /// made by the range.
        ///
        /// When changing the selection, the range is always normalised so that the anchor and cursor
        /// are located at either end of the modified range. For example when selecting items 1, 2, 3 with
        /// the anchor located at 1 and the cursor at 3. When adding 0 to the selection, the new cursor
        /// will be at 0 but the anchor would be in the middle of the actually selected range making 2 and 3 incidentals.
        /// This may not happen and instead fully connected ranges (without non-selected items in between) must be
        /// spanned by the cursor and anchor. In this case, the anchor would be moved to item 3.
        case select(cursor: UUID, anchor: UUID, incidentals: Set<UUID>)
    }

    enum SelectionType {
        case focus, cursor, anchor, range, incidental
    }

    enum MoveDirection {
        case forward, backward
    }

    @Published private(set) var mode: Mode = .none {
        didSet {
            // Reset the caret when we exit focus mode
            if case .focus(_) = mode {} else {
                caret = .infinity
                lastMoveDirection = nil
            }

            // Synchronize selection with delegate
            if let selectionDelegate = self.selectionDelegate {
                var oldSelection: [UUID] = []
                var newSelection: [UUID] = []

                if case .select(let cursor, let anchor, let incidentals) = oldValue {
                    oldSelection = (cursor == anchor ? [cursor] : (delegate?.items(between: cursor, end: anchor) ?? [cursor, anchor])) + Array(incidentals)
                }

                if case .select(let cursor, let anchor, let incidentals) = mode {
                    newSelection = (cursor == anchor ? [cursor] : (delegate?.items(between: cursor, end: anchor) ?? [cursor, anchor])) + Array(incidentals)
                }

                let delta = newSelection.difference(from: oldSelection)
                selectionDelegate.focusEngine(didChangeSelectionBy: delta)
            }
        }
    }

    var caret: CGPoint = .infinity

    /// Direction into which the cursor was last moved. Reset when the mode changes.
    /// Only set when in focus mode and the cursor was moved by `moveCursor(in:)`
    private(set) var lastMoveDirection: MoveDirection?

    /// Whether the engine should go from .none to .focus when only a single item is selected
    var defaultToFocusMode: Bool = true

    weak var selectionDelegate: FocusEngineSelectionDelegate?
    weak var delegate: FocusEngineDelegate?

    /// Snapshot of the currently selected items
    var selected: [UUID] {
        switch mode {
        case .none:
            return []
        case .focus(let item):
            return [item]
        case .select(let cursor, let anchor, let incidentals):
            return (cursor == anchor ? [cursor] : (delegate?.items(between: cursor, end: anchor) ?? [cursor, anchor])) + Array(incidentals)
        }
    }

    var cursorPosition: UUID? {
        delegate?.lastItem(of: Set(selected))
    }

    func isSelected(_ item: UUID) -> Bool {
        selectionType(for: item, mode) != nil
    }

    func selectionType(for item: UUID, _ mode: Mode) -> SelectionType? {
        switch mode {
        case .none:
            return nil
        case .focus(let focusedItem):
            return item == focusedItem ? .focus : nil
        case .select(let cursor, let anchor, let incidentals):
            let range = delegate?.items(between: cursor, end: anchor) ?? []

            if cursor == item {
                return .cursor
            } else if anchor == item {
                return .anchor
            } else if incidentals.contains(item) {
                return .incidental
            } else if range.contains(item) {
                return .range
            } else {
                return nil
            }
        }
    }

    func toggle(_ item: UUID, ignoreFocus: Bool = false) {
        if isSelected(item) && !(mode == .focus(item: item) && ignoreFocus) {
            deselect(item)
        } else {
            select(item, ignoreFocus: ignoreFocus)
        }
    }

    func focus(_ item: UUID, resetMoveDirection: Bool = false) {
        if resetMoveDirection {
            lastMoveDirection = nil
        }

        mode = .focus(item: item)
    }

    func select(_ item: UUID, ignoreFocus: Bool = false) {
        switch mode {
        case .none:
            if defaultToFocusMode && !ignoreFocus {
                mode = .focus(item: item)
            } else {
                mode = .select(cursor: item, anchor: item, incidentals: .empty)
            }
        case .focus(let focusedItem):
            guard !(ignoreFocus && focusedItem == item) else {
                mode = .select(cursor: item, anchor: item, incidentals: .empty)
                break
            }

            guard focusedItem != item else { break }

            if neighborDirection(item, neighbor: focusedItem) != nil {
                mode = .select(cursor: item, anchor: focusedItem, incidentals: .empty)
            } else {
                mode = .select(cursor: item, anchor: item, incidentals: Set([focusedItem]))
            }
        case .select(let cursor, let anchor, let incidentals):
            guard !isSelected(item) else { break }

            let extended = extendSelection(by: item, cursor: cursor, anchor: anchor, incidentals: incidentals)

            var incidentals = incidentals
            if !extended {
                // If it can't extend the current selection it is an incidental
                incidentals.insert(item)
                mode = .select(cursor: cursor, anchor: anchor, incidentals: incidentals.union([item]))
            } else {
                // Since we extended the selection it could now touch some incidentals
                // For this reason we have to "normalize" the selection by adding connected incidentals to the range
                normalizeSelection()
            }
        }
    }

    func deselect(_ item: UUID) {
        switch mode {
        case .none:
            return
        case .focus:
            mode = .none
        case .select(let cursor, let anchor, let incidentals):
            if incidentals.contains(item) {
                mode = .select(cursor: cursor, anchor: anchor, incidentals: incidentals.subtracting([item]))
            } else if item == cursor && cursor == anchor && incidentals.isEmpty {
                // We are deselecting the last item
                mode = .none
            } else if item == cursor && cursor == anchor, let newCursor = incidentals.first {
                // Use one of the incidentals as the new anchor/cursor (preferably the one that was added last)
                let newIncidentals = incidentals.subtracting([newCursor])
                mode = .select(cursor: newCursor, anchor: newCursor, incidentals: newIncidentals)
                // Since the newly elected anchor/cursor may touch other incidentals, we have to normalize
                normalizeSelection()
            } else if item == cursor, let newCursor = nextItem(from: cursor, inDirectionOf: anchor) {
                // Move the cursor towards the anchor
                mode = .select(cursor: newCursor, anchor: anchor, incidentals: incidentals)
            } else if item == anchor, let newAnchor = nextItem(from: anchor, inDirectionOf: cursor) {
                // Move the anchor towards the cursor
                mode = .select(cursor: cursor, anchor: newAnchor, incidentals: incidentals)
            } else if (delegate?.items(between: cursor, end: anchor) ?? []).contains(item) {
                // Split the range into incidentals (between removed item and cursor) and subrange (between anchor and removed item)
                guard let delegate = delegate,
                      let newCursor = delegate.direction(from: anchor, to: item) == .forward ? delegate.item(before: item) : delegate.item(after: item)
                else { break }

                let newIncidentals = Set(delegate.items(between: item, end: cursor)).subtracting([item])

                mode = .select(cursor: newCursor, anchor: anchor, incidentals: incidentals.union(newIncidentals))
            }
        }
    }

    func selectAll() {
        guard let first = delegate?.firstItem(), let last = delegate?.lastItem() else { return }
        mode = .select(cursor: last, anchor: first, incidentals: .empty)
    }

    func deselectAll() {
        mode = .none
    }

    /// Enters focus mode at the current cursor position or the last block if no block is selected
    func enterFocusMode() {
        switch mode {
        case .none:
            guard let lastItem = delegate?.lastItem() else { break }
            mode = .focus(item: lastItem)
        case .focus:
            break
        case .select(let cursor, _, _):
            mode = .focus(item: cursor)
        }
    }

    func moveCursor(to block: UUID) {
        var anchor: UUID? = nil
        var incidentals: Set<UUID> = .empty

        switch mode {
        case .focus(let item):
            anchor = item
        case .select(_, let oldAnchor, let oldIncidentals):
            anchor = oldAnchor
            incidentals = oldIncidentals
        default:
            break
        }

        guard let newAnchor = anchor else { return }

        mode = .select(cursor: block, anchor: newAnchor, incidentals: incidentals)
        normalizeSelection()
    }

    /// Moves the cursor and retains the selection.
    /// If it moves towards the anchor, the selection is reduced.
    /// Moving away from the anchor adds an element to the selection.
    /// In case the engine was in focus mode, it adds whatever element is in the given direction
    ///     and switches to selection mode.
    func moveCursor(_ direction: MoveDirection, retainSelection: Bool = false) {
        guard let delegate = delegate else { return }

        switch mode {
        case .none:
            switch direction {
            case .backward:
                guard let lastItem = delegate.lastItem() else {
                    mode = .none
                    return
                }

                select(lastItem)
            case .forward:
                guard let firstItem = delegate.firstItem() else {
                    mode = .none
                    return
                }

                select(firstItem)
            }

        case .focus(let item):
            guard let newItem = nextItem(from: item, inDirection: direction) else {
                return
            }

            if retainSelection {
                select(newItem)
            } else {
                lastMoveDirection = direction
                focus(newItem)
            }

        case .select(let cursor, let anchor, _):
            let cursorDirection = delegate.direction(from: anchor, to: cursor)

            // If we do not want to retain the selection, select either end of the selection
            //      or move the selection in `direction` if we only selected one item.
            guard retainSelection else {
                if cursor == anchor {
                    guard let newItem = nextItem(from: cursor, inDirection: direction) else { return }
                    mode = .select(cursor: newItem, anchor: newItem, incidentals: .empty)
                } else {
                    if cursorDirection == direction {
                        mode = .select(cursor: cursor, anchor: cursor, incidentals: .empty)
                    } else {
                        mode = .select(cursor: anchor, anchor: anchor, incidentals: .empty)
                    }
                }

                return
            }

            if cursor == anchor || cursorDirection == direction {
                // Extend the selection in the given direction
                guard let newItem = nextItem(from: cursor, inDirection: direction) else {
                    return
                }

                select(newItem)
            } else if cursor != anchor && cursorDirection != direction {
                // Reduce the selection towards the anchor
                deselect(cursor)
            } else {
                fatalError("Unreachable")
            }
        }
    }

    private func neighborDirection(_ lhs: UUID, neighbor: UUID) -> MoveDirection? {
        guard let delegate = delegate else { return nil }

        if delegate.item(before: lhs) == neighbor {
            return .backward
        } else if delegate.item(after: lhs) == neighbor {
            return .forward
        } else {
            return nil
        }
    }

    private func nextItem(from item: UUID, inDirectionOf otherItem: UUID) -> UUID? {
        guard let delegate = delegate else { return nil }

        let direction = delegate.direction(from: item, to: otherItem)
        return nextItem(from: item, inDirection: direction)
    }

    private func nextItem(from item: UUID, inDirection direction: MoveDirection) -> UUID? {
        guard let delegate = delegate else { return nil }

        switch direction {
        case .backward:
            return delegate.item(before: item)
        case .forward:
            return delegate.item(after: item)
        }
    }

    /// Normalizes the selection by extending the range spanned by cursor and anchor by touching incidentals.
    private func normalizeSelection() {
        var consumedIncidental = true

        while consumedIncidental {
            guard case .select(let cursor, let anchor, let incidentals) = mode else { break }
            consumedIncidental = false

            for incidental in incidentals {
                if extendSelection(by: incidental, cursor: cursor, anchor: anchor, incidentals: incidentals.subtracting([incidental])) {
                    consumedIncidental = true
                    break
                }
            }
        }
    }

    /// Attempts to extend the selection by the item. Returns false if the item does not touch the selection.
    /// Results in undefined behaviour, if the item is already selected!
    private func extendSelection(by item: UUID, cursor: UUID, anchor: UUID, incidentals: Set<UUID>) -> Bool {
        // If the new item is next to the cursor, just move the cursor
        if neighborDirection(item, neighbor: cursor) != nil {
            mode = .select(cursor: item, anchor: anchor, incidentals: incidentals)
            return true
        }
        // If the new item is next to the anchor, put the cursor to the selected item and move the anchor to the other end
        else if neighborDirection(item, neighbor: anchor) != nil {
            mode = .select(cursor: item, anchor: cursor, incidentals: incidentals)
            return true
        } else {
            return false
        }
    }
}

protocol FocusEngineSelectionDelegate: class {
    func focusEngine(didChangeSelectionBy delta: CollectionDifference<UUID>)
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

    // Returned result is inclusive bounds
    func items(between start: UUID, end: UUID) -> ArraySlice<UUID>

    func allItems() -> [UUID]
}

extension Set {
    static var empty: Self {
        Set()
    }
}

extension CGPoint {
    static var infinity: CGPoint {
        CGPoint(x: CGFloat.infinity, y: CGFloat.infinity)
    }
}
