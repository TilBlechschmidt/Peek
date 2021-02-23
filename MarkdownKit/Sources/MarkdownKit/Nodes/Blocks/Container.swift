//
//  Blockquote.swift
//  
//
//  Created by Til Blechschmidt on 22.02.21.
//

import Foundation

struct Container: Equatable, BlockNodeVariant {
    var debugDescription: String {
        "Container(variant: \(String(describing: variant)))"
    }

    let variant: Variant

    enum Variant: CaseIterable {
        case blockquote
        case admonition

        var marker: Token.Variant {
            switch self {
            case .blockquote:
                return .greaterThan
            case .admonition:
                return .pipe
            }
        }
    }

    struct Parser: SimpleNodeVariantParser {
        var childVariantRestriction: VariantRestriction {
            .closure({ !$0.isEqual(to: Container(variant: variant)) })
        }

        let variant: Variant

        func read(using reader: inout TokenReader) throws -> (NodeVariant, [Token]) {
            var childTokens: [Token] = []

            var lineCount = 0
            while !reader.didReachEnd {
                if lineCount == 0 {
                    try readMarker(using: &reader)
                } else if reader.attemptOrRewind({ try readMarker(using: &$0) }) == nil {
                    break
                }

                lineCount += 1

                let (lineTokens, reachedBlankLine) = try reader.advanceToNextLine()
                childTokens.append(contentsOf: lineTokens)

                if reachedBlankLine {
                    break
                }
            }

            return (Container(variant: variant), childTokens)
        }

        func readMarker(using reader: inout TokenReader) throws {
            reader.readMultiple(of: [.whitespace])
            try reader.read(variant.marker)
            try reader.read(.whitespace)
        }
    }
}
