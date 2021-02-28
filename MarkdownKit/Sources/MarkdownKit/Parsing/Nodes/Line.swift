//
//  Line.swift
//  
//
//  Created by Til Blechschmidt on 26.02.21.
//

import Foundation

public struct Line {
    private var input: Substring
    private var currentOffset: Substring.Index
    private var matchers: [NodeMatcher]

    // TODO We mostly only interact with the stack bottom. Might make sense to convert it to a queue instead.
    public private(set) var stack: [LineContent] = []

    /// Exclusive upper bound of this line object
    public var upperBound: Substring.Index {
        currentOffset
    }

    /// True when the line contains no characters or only whitespace/newlines.
    public var isEmpty: Bool {
        guard stack.count > 0 else {
            return true
        }

        for content in stack {
            switch content {
            case .indentation:
                continue
            case .text(let text):
                if !input[text].allSatisfy({ $0.isWhitespace }) {
                    return false
                }
            case .block:
                return false
            }
        }

        return true
    }

    /// True if the line only contains .text elements, .indentation elements.
    /// An empty line does **not** count as text!
    public var isText: Bool {
        guard stack.count > 0 else {
            return false
        }

        for content in stack {
            switch content {
            case .indentation:
                continue
            case .text:
                continue
            case .block:
                return false
            }
        }

        return true
    }

    public init(from string: Substring, matchers: [NodeMatcher]) {
        // Property initialization
        input = string
        currentOffset = string.startIndex
        self.matchers = matchers

        // Reading the line until no block matchers match anymore
        while currentOffset < input.endIndex {
            if let content = readContent() {
                stack.append(content)
            } else {
                break
            }
        }

        // If we have not reached the end of the line/file then whatever is next is not a block.
        // Thus it must be text, so we append it to the stack.
        if currentOffset < input.endIndex && input[currentOffset] == "\n" {
            currentOffset = input.index(after: currentOffset)
        } else if currentOffset < input.endIndex {
            let upperBound = input[currentOffset...]
                .firstIndex(of: "\n")
                .flatMap { input[currentOffset...].index(after: $0) }
                ?? input[currentOffset...].endIndex

            stack.append(.text(currentOffset..<upperBound))

            currentOffset = upperBound
        }
    }

    private func determineIndentation() -> (count: Int, upperBound: Substring.Index) {
        if input[currentOffset] != .whitespace {
            return (count: 0, upperBound: currentOffset)
        }

        let lineString = input[currentOffset...]

        var index = 0
        for (idx, (character, characterIndex)) in zip(lineString, lineString.indices).enumerated() {
            if character != .whitespace {
                return (count: idx, upperBound: characterIndex)
            }

            index = idx
        }

        return (count: index + 1, upperBound: lineString.endIndex)
    }

    private mutating func readContent() -> LineContent? {
        let indentation = determineIndentation()

        if indentation.count > 0 {
            currentOffset = indentation.upperBound
            return .indentation(indentation.count)
        }

        for matcher in matchers {
            if let match = matcher.match(substring: input[currentOffset...]) {
                matchers = matchers.filter { match.0.allows(childMatcher: $0) }
                currentOffset = match.upperBound
                return .block(match.0)
            }
        }

        return nil
    }

    public mutating func ignoreIndentation() {
        while !stack.isEmpty {
            if case .indentation = stack[0] {
                stack.remove(at: 0)
            } else {
                break
            }
        }
    }

    public mutating func popStackBottom() -> LineContent? {
        guard stack.count > 0 else { return nil }
        return stack.remove(at: 0)
    }

    public func peekStackBottom() -> LineContent? {
        guard stack.count > 0 else { return nil }
        return stack[0]
    }
}
