//
//  CodeSpan.swift
//  
//
//  Created by Til Blechschmidt on 21.02.21.
//

import Foundation

struct CodeSpan: Equatable, InlineNodeVariant {
    public var debugDescription: String {
        "CodeSpan"
    }

    struct Parser: SimpleNodeVariantParser {
        let childVariantRestriction: VariantRestriction = .whitelist([VerbatimText.self])

        func read(using reader: inout TokenReader) throws -> (NodeVariant, [Token]) {
            let count = reader.readCount(of: .backtick)
            try require(count > 0)

            _ = try? reader.read(.whitespace)

            // Read up to the closing delimiter, consuming at most `count` backticks
            var tokens: [Token] = []
            while !reader.didReachEnd {
                if let _ = reader.attemptOrRewind({
                    _ = try? $0.read(.whitespace)
                    let endCount = $0.readCount(of: .backtick, upTo: count)
                    try require(endCount == count)
                }) {
                    return (CodeSpan(), tokens)
                } else {
                    tokens.append(try reader.advance())
                }
            }

            throw TokenReader.Error()
        }
    }
}
