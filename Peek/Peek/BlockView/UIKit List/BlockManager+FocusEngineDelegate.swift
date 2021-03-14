//
//  BlockManager+FocusEngineDelegate.swift
//  Peek
//
//  Created by Til Blechschmidt on 14.03.21.
//

import Foundation

extension BlockManager: FocusEngineDelegate {
    func direction(from origin: UUID, to target: UUID) -> FocusEngine.MoveDirection {
        guard let originIndex = blockIDs.firstIndex(of: origin), let targetIndex = blockIDs.firstIndex(of: target) else {
            return .forward
        }

        return originIndex < targetIndex ? .forward : .backward
    }

    func firstItem() -> UUID? {
        blockIDs.first
    }

    func lastItem() -> UUID? {
        blockIDs.last
    }

    func firstItem(of set: Set<UUID>) -> UUID? {
        blockIDs.first { set.contains($0) }
    }

    func lastItem(of set: Set<UUID>) -> UUID? {
        blockIDs.last { set.contains($0) }
    }

    func item(after other: UUID) -> UUID? {
        guard let index = blockIDs.firstIndex(of: other), index < blockIDs.count - 1 else {
            return nil
        }

        return blockIDs[index + 1]
    }

    func item(before other: UUID) -> UUID? {
        guard let index = blockIDs.firstIndex(of: other), index > 0 else {
            return nil
        }

        return blockIDs[index - 1]
    }

    func allItems() -> [UUID] {
        blockIDs
    }
}
