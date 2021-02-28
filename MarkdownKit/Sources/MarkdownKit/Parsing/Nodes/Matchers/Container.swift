//
//  Container.swift
//  
//
//  Created by Til Blechschmidt on 26.02.21.
//

import Foundation

public struct Container: CustomDebugStringConvertible, Equatable, Node {
    public var debugDescription: String {
        "Container(variant: \(String(describing: variant)))"
    }

    public enum Variant: Character, Equatable {
        case blockquote = ">"
        case admonition = "|"
    }

    public let variant: Variant

    public func allows(childMatcher: NodeMatcher) -> Bool {
        if let containerMatcher = childMatcher as? Matcher {
            return containerMatcher.variant != variant
        } else {
            return true
        }
    }

    public func `continue`(on line: Line) -> Line? {
        var remainingLine = line
        remainingLine.ignoreIndentation()

        // Paragraphs are allowed to continue lazily :)
        if remainingLine.peekStackBottom() == .some(.block(Paragraph())) {
            return line
        }

        guard !remainingLine.isEmpty, remainingLine.popStackBottom() == .some(.block(self)) else {
            return nil
        }

        return remainingLine
    }

    public struct Matcher: NodeMatcher {
        let variant: Variant

        // TODO Prevent nested containers by passing in the currently open stack and checking it
        public func match(substring: Substring) -> NodeMatch? {
            guard substring.starts(with: "\(variant.rawValue)") else {
                return nil
            }

            let prefixLength = substring.starts(with: "\(variant.rawValue) ") ? 2 : 1
            let upperBound = substring.index(substring.startIndex, offsetBy: prefixLength)

            return (Container(variant: variant), upperBound: upperBound)
        }
    }
}
