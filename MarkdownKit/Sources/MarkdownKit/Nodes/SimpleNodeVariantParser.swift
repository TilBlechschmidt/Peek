//
//  SimpleNodeVariantParser.swift
//  
//
//  Created by Til Blechschmidt on 23.02.21.
//

import Foundation

protocol SimpleNodeVariantParser: NodeVariantParser {
    /// Parses a variant of content and returns the variant as well as unconsumed child tokens
    func read(using reader: inout TokenReader) throws -> (NodeVariant, [Token])
}

extension SimpleNodeVariantParser {
    func read(using reader: inout TokenReader, _ variantRestriction: VariantRestriction, _ childParser: Parser) throws -> Node {
        let previousReader = reader

        let (variant, childTokens) = try self.read(using: &reader)
        try require(variantRestriction.allows(variant: variant))

        let consumedTokens = (try reader.tokens(since: previousReader)).filter { !childTokens.contains($0) }
        let childNodes = try childParser.parse(childTokens)

        return Node(consumedTokens: consumedTokens, variant: variant, children: childNodes)
    }
}
