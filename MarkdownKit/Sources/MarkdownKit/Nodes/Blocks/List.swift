//
//  List.swift
//  
//
//  Created by Til Blechschmidt on 23.02.21.
//

import Foundation

// -- List parsing
//      - Lists and ListItems are two different things
//      - Lists basically just delegate to the ListItem.Parser
//          - Each List starts off by parsing a single ListItem
//          - Each consecutive ListItem has to be of the same variant
//          - Encountering a different ListItem variant or failing to parse a list item closes the List
//      - ListItems are fancy Containers
//          - The first line has to start with the marker and a space
//          - Consecutive lines may start with two whitespaces (which are 'consumed' by the ListItem)
//          - The remaining, unconsumed tokens are then parsed by the child Parser (much like Containers do)
//          - Blank lines terminate a ListItem
//          - Leading whitespace is allowed (and added to the number of leading whitespaces required in consecutive lines)
//          - Leading blank lines are disallowed (unlike Markdown) -> although maybe due to the way the Parser works with trimLineFeedForChildren it might turn out to work, if so, just accept/allow it :D
//
//      - Figure out how to treat stray list items with high degrees of indentation
//          - Maybe just treat them as regular lists and instead of deriving the indentation of ListItem content from the Marker, use the list items leading whitespace count (+ 2 for the marker and space)?

typealias MarkdownParser = Parser

struct List: Equatable, NodeVariant {
    var debugDescription: String {
        "List(variant: \(String(describing: variant)))"
    }

    let variant: ListItem.Variant

    struct Parser: NodeVariantParser {
        var childVariantRestriction: VariantRestriction = ListItem.Parser().childVariantRestriction
        let listItemParser = ListItem.Parser()

        func read(using reader: inout TokenReader, _ variantRestriction: VariantRestriction, _ childParser: MarkdownParser) throws -> Node {
            let initialReader = reader
            let leadingWhitespace = reader.readCount(of: .whitespace)
            let firstListItemNode = try listItemParser.read(using: &reader, variantRestriction, childParser)

            guard let listVariant = (firstListItemNode.variant as? ListItem)?.variant else {
                throw TokenReader.Error()
            }

            let list = List(variant: listVariant)

            try require(variantRestriction.allows(variant: list))

            var listItemNodes = [firstListItemNode]

            while !reader.didReachEnd {
                let previousReader = reader

                // Consume any number of blank lines
                reader.consumeBlankLines()

                // Attempt to read a list item
                if reader.attemptOrRewind({ try require($0.readCount(of: .whitespace) == leadingWhitespace) }) != nil,
                   let listItemNode = try? listItemParser.readOrRewind(using: &reader, variantRestriction, childParser),
                   let listItem = listItemNode.variant as? ListItem,
                   listItem.variant == listVariant
                {
                    listItemNodes.append(listItemNode)
                } else {
                    reader = previousReader
                    break
                }
            }

            return Node(tokens: try reader.tokens(since: initialReader), variant: list, children: listItemNodes)
        }
    }
}

// TODO Move somewhere :D
// -- Obsidian
// Reasons against it from CGPGrey
// - It is an electron app
// - Future existence
    // - Tiny development team
    // - No real monetization plans
// - No iOS/iPad Apps
//
// Reasons for it from CGPGrey:
//      - Very easy to open a bunch of little windows
//          - Notes are index card sized
//          - Fit a lot of cards on a big screen
//          - Make it easy to do this
//      - 80's theme lol
