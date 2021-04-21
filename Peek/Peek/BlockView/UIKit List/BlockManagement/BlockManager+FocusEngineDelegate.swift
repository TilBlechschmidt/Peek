//
//  BlockManager+FocusEngineDelegate.swift
//  Peek
//
//  Created by Til Blechschmidt on 18.04.21.
//

import Foundation

extension BlockManager: FocusEngineDelegate {
    func direction(from origin: UUID, to target: UUID) -> FocusEngine.MoveDirection {
        guard let originIndex = index(of: origin), let targetIndex = index(of: target) else {
            return .forward
        }

        return originIndex < targetIndex ? .forward : .backward
    }

    func firstItem() -> UUID? {
        blocks.value.first?.id
    }

    func lastItem() -> UUID? {
        blocks.value.last?.id
    }

    func firstItem(of set: Set<UUID>) -> UUID? {
        let block = blocks.value.first { set.contains($0.id) }
        return block?.id
    }

    func lastItem(of set: Set<UUID>) -> UUID? {
        let block = blocks.value.last { set.contains($0.id) }
        return block?.id
    }

    func item(after other: UUID) -> UUID? {
        guard let index = index(of: other), index < blocks.value.count - 1 else {
            return nil
        }

        return blocks.value[index + 1].id
    }

    func item(before other: UUID) -> UUID? {
        guard let index = index(of: other), index > 0 else {
            return nil
        }

        return blocks.value[index - 1].id
    }

    func items(between start: UUID, end: UUID) -> ArraySlice<UUID> {
        guard let startIndex = index(of: start), let endIndex = index(of: end) else {
            return [start, end]
        }

        if startIndex < endIndex {
            return ArraySlice(blocks.value[startIndex...endIndex].map { $0.id })
        } else if startIndex > endIndex {
            return ArraySlice(blocks.value[endIndex...startIndex].map { $0.id })
        } else {
            return [start, end]
        }
    }

    func allItems() -> [UUID] {
        blocks.value.map { $0.id }
    }
}
