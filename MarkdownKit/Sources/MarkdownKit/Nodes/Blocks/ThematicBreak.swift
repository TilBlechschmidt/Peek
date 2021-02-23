//
//  File.swift
//  
//
//  Created by Til Blechschmidt on 22.02.21.
//

import Foundation

struct ThematicBreak: Equatable, BlockNodeVariant {
    var debugDescription: String {
        "ThematicBreak(variant: \(String(describing: variant)))"
    }

    let variant: Variant

    enum Variant {
        case dots
        case line
        case thickLine

        static var all: [Variant] = [.dots, .line, .thickLine]

        static func from(token: Token) -> Self? {
            switch token.variant {
            case .emphasis(.bold): // "*"
                return .dots
            case .emphasis(.strikethrough): // "-"
                return .line
            case .emphasis(.underline): // "_"
                return .thickLine
            default:
                return nil
            }
        }

        var tokenVariant: Token.Variant {
            switch self {
            case .dots:
                return .emphasis(.bold)
            case .line:
                return .emphasis(.strikethrough)
            case .thickLine:
                return .emphasis(.underline)
            }
        }
    }

    struct Parser: SimpleNodeVariantParser {
        let childVariantRestriction: VariantRestriction = .disallowAll

        func read(using reader: inout TokenReader) throws -> (NodeVariant, [Token]) {
            // Discard leading whitespace
            reader.readMultiple(of: [.whitespace])

            guard !reader.didReachEnd, let variant = Variant.from(token: reader.currentToken) else {
                throw TokenReader.Error()
            }

            try require(reader.readCount(of: variant.tokenVariant) > 2)

            // Allow trailing whitespace
            reader.readMultiple(of: [.whitespace])

            // Expect lineFeed at the end
            // This implicitly requires that there may be no tokens
            // other than whitespaces and variant.tokenVariant
            try reader.read(.lineFeed)

            return (ThematicBreak(variant: variant), [])
        }
    }
}
