//
//  Paragraph.swift
//  
//
//  Created by Til Blechschmidt on 26.02.21.
//

import Foundation

public struct Paragraph: CustomDebugStringConvertible, Equatable, Node {
    public var debugDescription: String {
        "Paragraph"
    }

    public func allows(childMatcher: NodeMatcher) -> Bool {
        false
    }

    public func `continue`(on line: Line) -> Line? {
        var remainingLine = line
        remainingLine.ignoreIndentation()

        // TODO Could we have a line that is not a paragraph but still contains text?
        guard remainingLine.popStackBottom() == .some(.block(self)), remainingLine.isText else {
            return nil
        }

        return remainingLine
    }

    public struct Matcher: NodeMatcher {
        public func match(substring: Substring) -> NodeMatch? {
            let endOfLine = substring.firstIndex(of: "\n") ?? substring.endIndex

            guard !substring[..<endOfLine].allSatisfy({ $0.isWhitespace }) else {
                return nil
            }

            return (Paragraph(), substring.startIndex)
        }
    }
}
