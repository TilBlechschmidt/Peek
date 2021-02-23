//
//  File.swift
//  
//
//  Created by Til Blechschmidt on 22.02.21.
//

import Foundation

struct CodeBlock: Equatable, BlockNodeVariant {
    var debugDescription: String {
        "CodeBlock(language: '\(language)')"
    }

    let language: String

    struct Parser: SimpleNodeVariantParser {
        let trimNewlinesInChildren = false
        let childVariantRestriction: VariantRestriction = .whitelist([VerbatimText.self])

        func read(using reader: inout TokenReader) throws -> (NodeVariant, [Token]) {
            // Discard leading whitespaces
            reader.readMultiple(of: [.whitespace])

            // Read opening delimiter
            let count = reader.readCount(of: .backtick)
            try require(count > 2)

            // Read language tag (may not contain backticks)
            // TODO This eats leading newlines in the CodeBlocks content :(
            let language = try reader.readUntil(encountering: .lineFeed)
            try require(!language.contains { $0.variant == .backtick })

            var tokens: [Token] = []
            while !reader.didReachEnd {
                let previousReader = reader

                // See if we can read a closing delimiter of at least the size of the opening delimiter
                // Allows for whitespace and then requires a trailing newline.
                if reader.readCount(of: .backtick) >= count {
                    reader.readMultiple(of: [.whitespace])

                    if (try? reader.read(.lineFeed)) != nil {
                        break
                    }
                }

                reader = previousReader
                tokens.append(try reader.advance())
            }

            return (CodeBlock(language: language.reduce("", { $0 + $1.variant.textRepresentation }).trimmingCharacters(in: .whitespacesAndNewlines)), tokens)
        }
    }
}
