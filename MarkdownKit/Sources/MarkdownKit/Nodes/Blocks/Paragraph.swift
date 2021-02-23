//
//  Paragraph.swift
//  
//
//  Created by Til Blechschmidt on 22.02.21.
//

import Foundation

public struct Paragraph: Equatable, BlockNodeVariant {
    public var debugDescription: String {
        "Paragraph"
    }

    struct Parser: SimpleNodeVariantParser {
        let trimNewlinesInChildren = false
        let childVariantRestriction: VariantRestriction = .inlineVariants

        // TODO Extend this to also allow the more generic NodeVariantParser
        let interrupters: [SimpleNodeVariantParser] = [
            ListItem.Parser(),
            ThematicBreak.Parser(),
            Heading.Parser(),
            CodeBlock.Parser(),
            Container.Parser(variant: .blockquote),
            Container.Parser(variant: .admonition)
        ]

        func read(using reader: inout TokenReader) throws -> (NodeVariant, [Token]) {
            // Read everything until the next blankLine or EOF
            var tokens: [Token] = []

            while !reader.didReachEnd {
                let (lineTokens, reachedBlankLine) = try reader.advanceToNextLine()
                tokens.append(contentsOf: lineTokens)

                if reachedBlankLine {
                    break
                }

                // Check if the paragraph is being interrupted
                var interrupted = false
                for interrupter in interrupters {
                    let previousReader = reader

                    if (try? interrupter.read(using: &reader)) != nil {
                        reader = previousReader
                        interrupted = true
                        break
                    }

                    reader = previousReader
                }

                if interrupted {
                    break
                }
            }

            // Remove the trailing lineFeed if applicable
            if tokens.last?.variant == .some(.lineFeed) {
                _ = tokens.popLast()
            }

            // Strip any leading or trailing whitespace
            while tokens.last?.variant == .some(.whitespace) {
                _ = tokens.popLast()
            }
            while tokens.first?.variant == .some(.whitespace) {
                _ = tokens.removeFirst()
            }

            return (Paragraph(), tokens)
        }
    }
}
