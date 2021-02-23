//
//  Emphasis.swift
//  
//
//  Created by Til Blechschmidt on 21.02.21.
//

import Foundation

// TODO Add requirement that emphasis needs children, otherwise shouldn't parse

public struct Emphasis: Equatable, InlineNodeVariant {
    public var debugDescription: String {
        "Emphasis(.\(String(describing: variant)))"
    }

    let variant: Variant

    public enum Variant: Equatable, CaseIterable {
        case italics
        case bold
        case underline
        case highlight
        case strikethrough
        case `subscript`
        case superscript
    }
}

extension Emphasis {
    static var parsers: [SimpleNodeVariantParser] {
        Variant.allCases.map { Emphasis.Parser(variant: $0) }
    }

    struct Parser: SimpleNodeVariantParser {
        let childVariantRestriction: VariantRestriction = .inlineVariants
        let variant: Variant

        func read(using reader: inout TokenReader) throws -> (NodeVariant, [Token]) {
            // Read the opening delimiter
            try reader.read(.emphasis(variant))

            // Read up to the closing delimiter (inclusive)
            var tokens = try reader.readUntil(encountering: .emphasis(variant))

            // Remove the closing delimiter from the content
            guard let _ = tokens.popLast() else {
                throw TokenReader.Error()
            }

            return (Emphasis(variant: variant), tokens)
        }
    }
}
