//
//  BlockSource.swift
//  Peek
//
//  Created by Til Blechschmidt on 01.03.21.
//

import Foundation
import MarkdownKit

struct BlockSource {
    private(set) var blocks: [Block]

    private func findIndex(of identifier: Block.ID) -> Int? {
        blocks.firstIndex(where: { $0.id == identifier })
    }

    mutating func append(block: Block) {
        blocks.append(block)
    }

    mutating func add(_ block: Block, after identifier: Block.ID) {
        let index = findIndex(of: identifier) ?? 0
        blocks.insert(block, at: index)
    }

    mutating func replaceBlock(_ identifier: Block.ID, with block: Block) {
        guard let index = findIndex(of: identifier) else {
            return
        }

        print("Replacing block \(index) with \(block)")

        blocks[index] = block
    }

    mutating func removeBlock(withId identifier: Block.ID) {
        guard let index = findIndex(of: identifier) else {
            return
        }

        blocks.remove(at: index)
    }
}
