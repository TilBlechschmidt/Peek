//
//  Lexer.swift
//  
//
//  Created by Til Blechschmidt on 21.02.21.
//

import Foundation

public struct Lexer {
    private static let generators: [(String, Token.Generator)] = [
        // TODO Figure out how to deal with soft/hard line breaks, hardLineBreak probably requires their own token
        (#"\r?\n"#, { _ in .lineFeed }),
        (#"\\[[:punct:]]"#, { .escapedText($0[$0.index(after: $0.startIndex)...]) }),
        (#"[ \t]"#, { _ in .whitespace }),
        (#"`"#, { _ in .backtick }),
        (#"#"#, { _ in .hashtag }),
        (#">"#, { _ in .greaterThan }),
        (#"\|"#, { _ in .pipe }),
        (#"\+"#, { _ in .plus }),
        (#"\)"#, { _ in .closingBracket }),
        (#"\."#, { _ in .period }),
        (#"[0-9]+"#, { .number(UInt($0)!) }),
        (#"\/"#, { _ in .emphasis(.italics) }),
        (#"\*"#, { _ in .emphasis(.bold) }),
        (#"_"#, { _ in .emphasis(.underline) }),
        (#"="#, { _ in .emphasis(.highlight) }),
        (#"-"#, { _ in .emphasis(.strikethrough) }),
        (#"~"#, { _ in .emphasis(.subscript) }),
        (#"\^"#, { _ in .emphasis(.superscript) })
    ]

    public init() {}

    public func tokenize(string input: Substring) -> [Token] {
        var tokens: [Token] = []
        var currentIndex = input.startIndex

        while currentIndex != input.endIndex {
            var matched = false

            for (pattern, generator) in Lexer.generators {
                if let range = input.range(of: pattern, options: [.regularExpression, .anchored], range: currentIndex..<input.endIndex) {
                    if let variant = generator(input[range]) {
                        tokens.append(Token(variant, range: range))
                    }

                    currentIndex = range.upperBound
                    matched = true
                    break
                }
            }

            if !matched {
                // Build a text token from the non-matched characters
                let range = currentIndex..<input.index(after: currentIndex)
                tokens.append(Token(.text(input[range]), range: range))

                // Advance the index
                currentIndex = range.upperBound
            }
        }

        // Do some cleanup (merge consecutive text tokens)
        return tokens.reduce(into: []) { result, token in
            if case .text = token.variant, let previous_token = result.last, case .text = previous_token.variant {
                let range = previous_token.range.lowerBound..<token.range.upperBound
                result[result.count - 1] = Token(.text(input[range]), range: range)
            } else {
                result.append(token)
            }
        }
    }
}
