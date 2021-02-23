//
//  Heading.swift
//  
//
//  Created by Til Blechschmidt on 22.02.21.
//

import Foundation

struct Heading: Equatable, BlockNodeVariant {
    let level: Int

    public var debugDescription: String {
        "Heading(level: \(level))"
    }

    struct Parser: SimpleNodeVariantParser {
        let childVariantRestriction: VariantRestriction = VariantRestriction.whitelist([Paragraph.self]).union(.inlineVariants)

        func read(using reader: inout TokenReader) throws -> (NodeVariant, [Token]) {
            // Discard any leading whitespace
            reader.readCount(of: .whitespace)

            // Read the #'s
            let level = reader.readCount(of: .hashtag, upTo: 6)
            try require(level > 0)

            // Require a whitespace after the last #
            try reader.read(.whitespace)

            // Read everything until the end of the line
            var content = try reader.readUntil(encountering: .lineFeed, allowEndOfFile: true)

            // Remove trailing lineFeed from content
            while content.last?.variant == .some(.lineFeed) {
                _ = content.popLast()
            }

            return (Heading(level: level), content)
        }
    }
}
