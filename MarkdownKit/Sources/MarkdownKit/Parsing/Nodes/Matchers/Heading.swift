//
//  Heading.swift
//  
//
//  Created by Til Blechschmidt on 26.02.21.
//

import Foundation

public struct Heading: CustomDebugStringConvertible, Equatable, Node {
    public var debugDescription: String {
        "Heading(level: \(String(describing: level)))"
    }

    public let level: Int

    public func allows(childMatcher: NodeMatcher) -> Bool {
        false
    }

    public func `continue`(on line: Line) -> Line? {
        nil
    }

    public struct Matcher: NodeMatcher {
        public func match(substring: Substring) -> NodeMatch? {
            guard substring.starts(with: "#") else {
                return nil
            }

            var level = 0
            var upperBound = substring.startIndex
            var encounteredOtherContent = false
            for (index, character) in zip(substring.indices, substring) {
                if character == "#" {
                    level += 1
                } else {
                    upperBound = index
                    encounteredOtherContent = true
                    break
                }
            }

            // Don't allow more than 6 heading levels
            guard level <= 6 else {
                return nil
            }

            // If we did not encounter any other characters after the # then we encountered EOF
            // But since the loop ends before the EOF we have to mark it ourselves -.-
            if encounteredOtherContent == false {
                upperBound = substring.endIndex
            }

            // Require a whitespace or line ending after the last #
            guard upperBound == substring.endIndex || substring[upperBound].isWhitespace else {
                return nil
            }

            // Eat the whitespace :D
            if upperBound != substring.endIndex && substring[upperBound] == .whitespace {
                upperBound = substring.index(after: upperBound)
            }

            return (Heading(level: level), upperBound: upperBound)
        }
    }
}
