//
//  Token.swift
//  
//
//  Created by Til Blechschmidt on 21.02.21.
//

import Foundation

public struct Token: Equatable {
    public let variant: Variant
    public let range: Range<Substring.Index>
}

extension Token {
    typealias Generator = (Substring) -> Variant?

    public enum Variant: Equatable {
        case lineFeed
        case escapedText(Substring)
        case whitespace
        case backtick
        case hashtag
        case greaterThan
        case pipe
        case plus
        case closingBracket
        case period
        case number(UInt)
        case emphasis(Emphasis.Variant)
        case text(Substring)

        public var textRepresentation: String {
            switch self {
            case .lineFeed:
                return "\n"
            case .escapedText(let content):
                return "\\\(content)"
            case .whitespace:
                return " "
            case .backtick:
                return "`"
            case .hashtag:
                return "#"
            case .greaterThan:
                return ">"
            case .pipe:
                return "|"
            case .plus:
                return "+"
            case .closingBracket:
                return ")"
            case .period:
                return "."
            case .number(let value):
                return "\(value)"
            case .emphasis(let variant):
                switch variant {
                case .italics:
                    return "/"
                case .bold:
                    return "*"
                case .underline:
                    return "_"
                case .highlight:
                    return "="
                case .strikethrough:
                    return "-"
                case .subscript:
                    return "~"
                case .superscript:
                    return "^"
                }
            case .text(let content):
                return String(content)
            }
        }
    }

    public init(_ variant: Variant, range: Range<Substring.Index>) {
        self.variant = variant
        self.range = range
    }
}
