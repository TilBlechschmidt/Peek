//
//  BlockManager+FocusEngineDelegate.swift
//  Peek
//
//  Created by Til Blechschmidt on 18.04.21.
//

import Foundation

extension BlockManager: FocusEngineDelegate {
    func direction(from origin: UUID, to target: UUID) -> FocusEngine.MoveDirection {
        guard let originIndex = blockIDs.value.firstIndex(of: origin), let targetIndex = blockIDs.value.firstIndex(of: target) else {
            return .forward
        }

        return originIndex < targetIndex ? .forward : .backward
    }

    func firstItem() -> UUID? {
        blockIDs.value.first
    }

    func lastItem() -> UUID? {
        blockIDs.value.last
    }

    func firstItem(of set: Set<UUID>) -> UUID? {
        blockIDs.value.first { set.contains($0) }
    }

    func lastItem(of set: Set<UUID>) -> UUID? {
        blockIDs.value.last { set.contains($0) }
    }

    func item(after other: UUID) -> UUID? {
        guard let index = blockIDs.value.firstIndex(of: other), index < blockIDs.value.count - 1 else {
            return nil
        }

        return blockIDs.value[index + 1]
    }

    func item(before other: UUID) -> UUID? {
        guard let index = blockIDs.value.firstIndex(of: other), index > 0 else {
            return nil
        }

        return blockIDs.value[index - 1]
    }

    func items(between start: UUID, end: UUID) -> ArraySlice<UUID> {
        guard let startIndex = blockIDs.value.firstIndex(of: start), let endIndex = blockIDs.value.firstIndex(of: end) else {
            return [start, end]
        }

        if startIndex < endIndex {
            return blockIDs.value[startIndex...endIndex]
        } else if startIndex > endIndex {
            return blockIDs.value[endIndex...startIndex]
        } else {
            return [start, end]
        }
    }

    func allItems() -> [UUID] {
        blockIDs.value
    }
}
