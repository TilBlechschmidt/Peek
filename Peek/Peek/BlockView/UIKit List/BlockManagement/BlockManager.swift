//
//  BlockManager.swift
//  Peek
//
//  Created by Til Blechschmidt on 13.04.21.
//

import Foundation
import Combine
import UIKit

class ContentBlock: Identifiable {
    let id: UUID

    init(_ id: UUID = UUID()) {
        self.id = id
    }
}

class BlockManager {
    let blockIDs: CurrentValueSubject<[UUID], Never> = CurrentValueSubject([])

    init(_ blocks: [UUID] = []) {
        blocks.forEach {
            append($0)
        }
    }

    func insert(_ block: UUID, before id: UUID) {
        guard !blockIDs.value.contains(block), let index = blockIDs.value.firstIndex(of: id) else { return }
        blockIDs.value.insert(block, at: index)
    }

    func insert(_ block: UUID, after id: UUID) {
        guard !blockIDs.value.contains(block), let index = blockIDs.value.firstIndex(of: id) else { return }
        blockIDs.value.insert(block, at: index + 1)
    }

    func append(_ block: UUID) {
        guard !blockIDs.value.contains(block) else { return }
        blockIDs.value.append(block)
    }

    func remove(_ id: UUID) {
        guard let index = blockIDs.value.firstIndex(of: id) else { return }
        blockIDs.value.remove(at: index)
    }

    func block(before blockID: UUID) -> UUID? {
        item(before: blockID)
    }

    func block(after blockID: UUID) -> UUID? {
        item(after: blockID)
    }
}
