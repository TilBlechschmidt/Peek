//
//  Parser.swift
//  
//
//  Created by Til Blechschmidt on 21.02.21.
//

import Foundation

// TODO: When reading a document initially, perform some "cleaning"
// -> Remove leading and trailing blank lines
// -> Replace tabs with four whitespaces

struct Parser {
    enum Error: Swift.Error {
        case unableToParseDocument
    }

    static let defaultParsers: [NodeVariantParser] = [
        // BlockNodes
        Container.Parser(variant: .admonition),
        Container.Parser(variant: .blockquote),
        CodeBlock.Parser(),
        List.Parser(),
        ThematicBreak.Parser(),
        Heading.Parser(),
        Paragraph.Parser(),
        // InlineNodes
        CodeSpan.Parser()
        ] + Emphasis.parsers + [
        Text.Parser(),
        VerbatimText.Parser()
    ]

    private(set) var trimNewlines: Bool
    private(set) var permittedVariants: VariantRestriction
    private(set) var parsers: [NodeVariantParser]

    public init(parsers: [NodeVariantParser] = defaultParsers, permittedVariants: VariantRestriction = .indifferent, trimNewlines: Bool = true) {
        self.trimNewlines = trimNewlines
        self.permittedVariants = permittedVariants
        self.parsers = parsers
    }

    public func parse(_ tokens: [Token]) throws -> [Node] {
        var reader = TokenReader(tokens: tokens)
        var nodes: [Node] = []

        while !reader.didReachEnd {
            // Trim any trailing .lineFeed or .blankLine after the previous node
            // TODO Figure out if this trimNewlines property solves the "lineBreak" crisis :D
            if trimNewlines {
                reader.readMultiple(of: [.lineFeed])
            }

            // If the trimming caused the reader to reach EOF, prematurely exit
            if reader.didReachEnd {
                break
            }

            guard let node = try? readNode(from: &reader) else { throw Error.unableToParseDocument }
            nodes.append(node)
        }

        return nodes
    }

    private func readNode(from reader: inout TokenReader) throws -> Node {
        for parser in parsers {
            let allowedChildren = permittedVariants.intersection(parser.childVariantRestriction)
            let childParser = Self(permittedVariants: allowedChildren, trimNewlines: parser.trimNewlinesInChildren)

            if let node = try? parser.readOrRewind(using: &reader, permittedVariants, childParser) {
                return node
            }
        }

        throw TokenReader.Error()
    }
}
