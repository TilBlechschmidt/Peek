//
//  BlockManager.swift
//  Peek
//
//  Created by Til Blechschmidt on 03.03.21.
//

import Foundation
import MarkdownKit

class BlockManager: ObservableObject {
    @Published private(set) var blockIDs: [Block.ID] = []
    private var blocks: [Block.ID: UIBlock] = [:]

    init(_ blocks: [UIBlock] = []) {
        blocks.forEach {
            append($0)
        }
    }

    subscript(index: Block.ID) -> UIBlock? {
        get { blocks[index] }
        set { blocks[index] = newValue }
    }

    func insert(_ block: UIBlock, after id: Block.ID) {
        guard !blocks.keys.contains(block.id), let index = blockIDs.firstIndex(of: id) else { return }
        blocks[block.id] = block
        blockIDs.insert(block.id, at: index + 1)
    }

    func insert(_ block: UIBlock, before id: Block.ID) {
        guard !blocks.keys.contains(block.id), let index = blockIDs.firstIndex(of: id) else { return }
        blocks[block.id] = block
        blockIDs.insert(block.id, at: index)
    }

    func append(_ block: UIBlock) {
        guard !blocks.keys.contains(block.id) else { return }
        blocks[block.id] = block
        blockIDs.append(block.id)
    }

    func remove(_ id: Block.ID) {
        guard let index = blockIDs.firstIndex(of: id) else { return }
        blockIDs.remove(at: index)
        blocks.removeValue(forKey: id)
    }

    func block(before blockID: Block.ID) -> UIBlock? {
        guard let blockIndex = blockIDs.firstIndex(of: blockID), blockIndex - 1 >= 0, let previousBlock = blocks[blockIDs[blockIndex - 1]] else {
            return nil
        }

        return previousBlock
    }

    func block(after blockID: Block.ID) -> UIBlock? {
        guard let blockIndex = blockIDs.firstIndex(of: blockID), blockIndex + 1 < blockIDs.count, let nextBlock = blocks[blockIDs[blockIndex + 1]] else {
            return nil
        }

        return nextBlock
    }

    func connections(for blockID: Block.ID) -> Connection {
        guard let block = blocks[blockID], block.admonition || block.blockquote else {
            return []
        }

        var connections: Connection = []

        if let previousBlock = self.block(before: blockID),
           block.admonition == previousBlock.admonition
            && block.blockquote == previousBlock.blockquote {
            connections.insert(.previous)
        }

        if let nextBlock = self.block(after: blockID),
           block.admonition == nextBlock.admonition
            && block.blockquote == nextBlock.blockquote {
            connections.insert(.next)
        }

        return connections
    }
}

class UIBlock: ObservableObject {
    public let id: Block.ID

    @Published var admonition: Bool
    @Published var blockquote: Bool
    @Published var content: Block.Content

    public init(id: UUID = UUID(), admonition: Bool, blockquote: Bool, content: Block.Content) {
        self.id = id
        self.admonition = admonition
        self.blockquote = blockquote
        self.content = content
    }
}
