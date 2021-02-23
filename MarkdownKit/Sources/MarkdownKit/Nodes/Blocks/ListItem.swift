//
//  File.swift
//  
//
//  Created by Til Blechschmidt on 23.02.21.
//

import Foundation

struct ListItem: Equatable, NodeVariant {
    var debugDescription: String {
        "ListItem"
    }

    let variant: Variant

    enum Variant {
        case ordered
        case unordered
    }

    struct Parser: SimpleNodeVariantParser {
        var childVariantRestriction: VariantRestriction = .blacklist([CodeBlock.self, ThematicBreak.self])

        let markers: [(Variant, [Token.Variant])] = [
            (.unordered, [.emphasis(.bold)]),
            (.unordered, [.emphasis(.strikethrough)]),
            (.unordered, [.plus]),
        ] + (0..<9).map { (.ordered, [.number($0), .closingBracket]) }
        + (0..<9).map { (.ordered, [.number($0), .period]) }

        func read(using reader: inout TokenReader) throws -> (NodeVariant, [Token]) {
            let variant = try readMarker(using: &reader)

            // TODO Read content and "unshift" it like containers do
            var tokens: [Token] = []
            while !reader.didReachEnd {
                let (lineTokens, reachedBlankLine) = try reader.advanceToNextLine()
                tokens.append(contentsOf: lineTokens)

                if reachedBlankLine {
                    break
                }

                if reader.attemptOrRewind({ r -> Token in
                    try r.read(.whitespace)
                    return try r.read(.whitespace)
                }) == nil {
                    break
                }
            }

            return (ListItem(variant: variant), tokens)
        }

        private func readMarker(using reader: inout TokenReader) throws -> Variant {
            let initialReader = reader

            if let variant = try? readUnorderedMarker(using: &reader) {
                return variant
            } else {
                reader = initialReader
                return try readOrderedMarker(using: &reader)
            }
        }

        private func readUnorderedMarker(using reader: inout TokenReader) throws -> Variant {
            try reader.read(eitherOf: [.emphasis(.bold), .emphasis(.strikethrough), .plus])
            try reader.read(.whitespace)
            return .unordered
        }

        private func readOrderedMarker(using reader: inout TokenReader) throws -> Variant {
            let token = try reader.advance()

            if case .number(_) = token.variant {
                try reader.read(eitherOf: [.closingBracket, .period])
                try reader.read(.whitespace)
                return .ordered
            }

            throw TokenReader.Error()
        }
    }
}
