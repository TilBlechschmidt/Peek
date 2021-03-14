//
//  BlockManager.swift
//  Peek
//
//  Created by Til Blechschmidt on 08.03.21.
//

import Foundation
import MarkdownKit
import UIKit
import Combine

protocol BlockManagerDelegate: class {
    func blockWillChangeContent(from oldContent: Block.Content, to newContent: Block.Content, _ block: UIBlock)
}

class BlockManager: ObservableObject {
    @Published private(set) var blockIDs: [Block.ID] = []
    private var blocks: [Block.ID: (UIBlock, AnyCancellable)] = [:]

    weak var delegate: BlockManagerDelegate?

    init(_ blocks: [UIBlock] = []) {
        blocks.forEach {
            append($0)
        }
    }

    private(set) subscript(index: Block.ID) -> UIBlock? {
        get {
            blocks[index].flatMap { $0.0 }
        }
        set {
            blocks[index] = newValue.flatMap { ($0, observe($0)) }
        }
    }

    func insert(_ block: UIBlock, before id: Block.ID) {
        guard !blocks.keys.contains(block.id), let index = blockIDs.firstIndex(of: id) else { return }
        self[block.id] = block
        blockIDs.insert(block.id, at: index)
    }

    func insert(_ block: UIBlock, after id: Block.ID) {
        guard !blocks.keys.contains(block.id), let index = blockIDs.firstIndex(of: id) else { return }
        self[block.id] = block
        blockIDs.insert(block.id, at: index + 1)
    }

    func append(_ block: UIBlock) {
        guard !blocks.keys.contains(block.id) else { return }
        self[block.id] = block
        blockIDs.append(block.id)
    }

    func remove(_ id: Block.ID) {
        guard let index = blockIDs.firstIndex(of: id) else { return }
        blockIDs.remove(at: index)
        blocks.removeValue(forKey: id)
    }

    func block(before blockID: Block.ID) -> UIBlock? {
        guard let blockIndex = blockIDs.firstIndex(of: blockID), blockIndex - 1 >= 0, let previousBlock = self[blockIDs[blockIndex - 1]] else {
            return nil
        }

        return previousBlock
    }

    func block(after blockID: Block.ID) -> UIBlock? {
        guard let blockIndex = blockIDs.firstIndex(of: blockID), blockIndex + 1 < blockIDs.count, let nextBlock = self[blockIDs[blockIndex + 1]] else {
            return nil
        }

        return nextBlock
    }

    func connections(for blockID: Block.ID) -> Connection {
        guard let block = self[blockID], block.admonition || block.blockquote else {
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

    private func observe(_ block: UIBlock) -> AnyCancellable {
        block.$content.sink(receiveValue: { [weak self] in
            self?.delegate?.blockWillChangeContent(from: block.content, to: $0, block)
        })
    }
}

extension BlockManager {
    static var withDemoData: BlockManager {
        BlockManager([
            UIBlock(admonition: false, blockquote: false, content: .heading(level: 1, content: "Super important heading")),
            UIBlock(admonition: false, blockquote: false, content: .text("This is a wonderful and lovely test document! How about you do some research about what you can do?")),
            UIBlock(admonition: false, blockquote: false, content: .thematicBreak(.dots)),
            UIBlock(admonition: false, blockquote: false, content: .text("Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.")),
            UIBlock(admonition: false, blockquote: false, content: .text("Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.")),
            UIBlock(admonition: false, blockquote: false, content: .text("Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.")),
            UIBlock(admonition: true, blockquote: false, content: .text("Hello world!")),
            UIBlock(admonition: false, blockquote: true, content: .text("Hello world!")),
            UIBlock(admonition: true, blockquote: true, content: .text("Hello world!")),
            UIBlock(admonition: false, blockquote: false, content: .text("Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.")),
            UIBlock(admonition: true, blockquote: false, content: .text("Connected admonition!")),
            UIBlock(admonition: true, blockquote: false, content: .text("Let us see how well this works.")),
            UIBlock(admonition: false, blockquote: false, content: .text("Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.")),
            UIBlock(admonition: false, blockquote: true, content: .text("Connected blockquote!")),
            UIBlock(admonition: false, blockquote: true, content: .text("Let us see how well this works.")),
            UIBlock(admonition: false, blockquote: false, content: .text("Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.")),
            UIBlock(admonition: true, blockquote: true, content: .text("Connecting both at the same time now!")),
            UIBlock(admonition: true, blockquote: true, content: .text("Let us see how well this works.")),
        ])
    }
}

struct Connection: OptionSet, Hashable {
    let rawValue: Int

    static let previous = Connection(rawValue: 1 << 0)
    static let next     = Connection(rawValue: 1 << 1)

    var cornersWithRadius: CACornerMask {
        var set: CACornerMask = []

        if !contains(.previous) {
            set.insert(.layerMaxXMinYCorner)
            set.insert(.layerMinXMinYCorner)
        }

        if !contains(.next) {
            set.insert(.layerMaxXMaxYCorner)
            set.insert(.layerMinXMaxYCorner)
        }

        return set
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
