//
//  NodeVariantParser.swift
//  
//
//  Created by Til Blechschmidt on 21.02.21.
//

import Foundation

protocol NodeVariantParser {
    var childVariantRestriction: VariantRestriction { get }
    var trimNewlinesInChildren: Bool { get }

    func read(using reader: inout TokenReader, _ variantRestriction: VariantRestriction, _ childParser: Parser) throws -> Node
}

extension NodeVariantParser {
    var trimNewlinesInChildren: Bool {
        true
    }
    
    func readOrRewind(using reader: inout TokenReader, _ variantRestriction: VariantRestriction, _ childParser: Parser) throws -> Node {
        let previousReader = reader

        do {
            return try read(using: &reader, variantRestriction, childParser)
        } catch {
            reader = previousReader
            throw error
        }
    }
}
