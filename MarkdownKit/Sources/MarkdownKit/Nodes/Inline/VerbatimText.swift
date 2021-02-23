//
//  VerbatimText.swift
//  
//
//  Created by Til Blechschmidt on 21.02.21.
//

import Foundation

struct VerbatimText: Equatable, InlineNodeVariant {
    var debugDescription: String {
        "VerbatimText(\(String(reflecting: content.textRepresentation)))"
    }

    let content: Token.Variant

    struct Parser: SimpleNodeVariantParser {
        let childVariantRestriction: VariantRestriction = .disallowAll

        func read(using reader: inout TokenReader) throws -> (NodeVariant, [Token]) {
            var token = try reader.advance()

            if case .escapedText(_) = token.variant {
                // Replace the escaped text with the original text by converting the token into its original form
                token = Token(variant: .text(Substring(token.variant.textRepresentation)), range: token.range)
            }

            return (VerbatimText(content: token.variant), [])
        }
    }
}
