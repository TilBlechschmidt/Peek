//
//  FocusEngine.swift
//  Peek
//
//  Created by Til Blechschmidt on 07.03.21.
//

import Foundation
import Combine

class FocusEngine {
    enum Mode {
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

    @Published private(set) var mode: Mode = .none

    /// Whether the engine should go from .none to .focus when only a single item is selected
    var defaultToFocusMode: Bool = true

    weak var delegate: FocusEngineDelegate?

    var selection: Set<UUID> {
        switch mode {
        case .none:
            return []
        case .focus(let focusedItem):
            return Set(arrayLiteral: focusedItem)
        case .select(let cursor, let anchor, let incidentals):
            let range = delegate?.items(between: cursor, end: anchor) ?? []
            return Set(range + incidentals)
        }
    }

    func isSelected(_ item: UUID) -> Bool {
        selection.contains(item)
    }

    func toggle(_ item: UUID) {
        if isSelected(item) {
            deselect(item)
        } else {
            select(item)
        }
    }

    func focus(_ item: UUID) {
        mode = .focus(item: item)
    }

    func select(_ item: UUID) {
        switch mode {
        case .none:
            if defaultToFocusMode {
                mode = .focus(item: item)
            } else {
                mode = .select(cursor: item, anchor: item, incidentals: .empty)
            }
        case .focus(let focusedItem):
            if neighborDirection(item, neighbor: focusedItem) != nil {
                mode = .select(cursor: item, anchor: focusedItem, incidentals: .empty)
            } else {
                mode = .select(cursor: item, anchor: item, incidentals: Set([focusedItem]))
            }
        case .select(let cursor, let anchor, let incidentals):
            guard !isSelected(item) else { return }

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
                else { return }

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

    enum MoveDirection {
        case forward, backward
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
