//
//  Text.swift
//  
//
//  Created by Til Blechschmidt on 21.02.21.
//

import Foundation

struct Text: Equatable, InlineNodeVariant {
    var debugDescription: String {
        "Text(\(String(reflecting: content.textRepresentation)))"
    }

    let content: Token.Variant

    struct Parser: SimpleNodeVariantParser {
        let childVariantRestriction: VariantRestriction = .disallowAll

        func read(using reader: inout TokenReader) throws -> (NodeVariant, [Token]) {
            let token = try reader.advance()
            return (Text(content: token.variant), [])
        }
    }
}
