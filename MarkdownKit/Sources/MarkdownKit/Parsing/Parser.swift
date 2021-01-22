//
//  Parser.swift
//  
//
//  Created by Til Blechschmidt on 22.01.21.
//

import Foundation

public struct Parser {
    enum Error: Swift.Error {
        case unableToParseDocument
    }

    private(set) var blockTypes: [ReadableBlock.Type]

    init(blockTypes: [ReadableBlock.Type] = [Heading.self, Paragraph.self]) {
        self.blockTypes = blockTypes
    }

    public func parse(_ markdown: String) throws -> [Block] {
        var reader = Reader(string: markdown)
        var blocks: [Block] = []

        while !reader.didReachEnd {
            // Skip any blank lines between blocks
            // TODO: This also removes any leading whitespaces from blocks.
            //       Some blocks don't allow an infinite number of leading whitespaces!
            reader.discardWhitespacesAndNewlines()
            guard !reader.didReachEnd else { break }

            // Go through all block types and try parsing them
            guard let block = try? readBlock(from: &reader) else { throw Error.unableToParseDocument }
            blocks.append(block)
        }

        return blocks
    }

    private func readBlock(from reader: inout Reader) throws -> Block {
        for blockType in blockTypes {
            if let parsed = try? blockType.readOrRewind(using: &reader) {
                return parsed
            }
        }

        throw Reader.Error()
    }
}
