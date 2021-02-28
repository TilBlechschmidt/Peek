//
//  ThematicBreak.swift
//  
//
//  Created by Til Blechschmidt on 26.02.21.
//

import Foundation

public struct ThematicBreak: CustomDebugStringConvertible, Equatable, Node {
    public var debugDescription: String {
        "ThematicBreak(variant: \(String(describing: variant)))"
    }

    public enum Variant: Character, Equatable {
        case dots = "*"
        case line = "-"
        case thickLine = "_"
    }

    public let variant: Variant

    public func allows(childMatcher: NodeMatcher) -> Bool {
        false
    }

    public func `continue`(on line: Line) -> Line? {
        nil
    }

    public struct Matcher: NodeMatcher {
        public func match(substring: Substring) -> NodeMatch? {
            guard let first = substring.first, let variant = Variant(rawValue: first) else {
                return nil
            }

            // Find the end of the line
            let upperBound = substring.firstIndex(of: "\n") ?? substring.endIndex

            // Assert that only variant.rawValue or .whitespace characters may appear in the line
            var count = 0
            for character in substring[..<upperBound] {
                if character == variant.rawValue {
                    count += 1
                } else if character == .whitespace {
                    continue
                } else {
                    return nil
                }
            }

            // Require at least three markers
            guard count >= 3 else {
                return nil
            }

            return (ThematicBreak(variant: variant), upperBound: upperBound)
        }
    }
}
