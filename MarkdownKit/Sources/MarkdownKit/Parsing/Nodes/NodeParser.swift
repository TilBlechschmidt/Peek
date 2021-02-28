//
//  File.swift
//  
//
//  Created by Til Blechschmidt on 25.02.21.
//

import Foundation

extension Character {
    static var whitespace: Self { " " }
}

public struct NodeParser {
    public struct Options: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        // Emit lines with only whitespaces and newlines
        public static let emitWhitespace = Options(rawValue: 1 << 0)

        public static let `default`: Options = []
    }

    public let input: Substring
    public let matchers: [NodeMatcher]

    public var options: Options
    public weak var delegate: NodeParserDelegate? = nil

    internal var blockStack: [Node] = []
    internal var currentOffset: Substring.Index

    public init(_ input: Substring, options: Options = .default, matchers: [NodeMatcher] = defaultMatchers) {
        self.input = input
        self.matchers = matchers
        self.currentOffset = input.startIndex
        self.options = options
    }

    public mutating func start() {
        while currentOffset < input.endIndex {
            parseNextLine()
        }

        // Close all unclosed blocks at EOF
        closeBlocks(from: 0)
        delegate?.blockParserDidFinishParsing()
    }

    internal mutating func parseNextLine() {
        // Read the next line
        var line = Line(from: input[currentOffset...], matchers: matchers)

        // Go through the stack
        for index in blockStack.indices {
            let openBlock = blockStack[index]

            // Verify that the block can continue
            if let remainingLine = openBlock.continue(on: line) {
                line = remainingLine
            } else {
                // If it can not continue, pop the stack up to (including) the currently processed block
                closeBlocks(from: index)
                break
            }
        }

        // Open blocks for the remaining content of the line
        for content in line.stack {
            switch content {
            case .indentation:
                continue
            case .text(let range):
                if options.contains(.emitWhitespace) || !input[range].allSatisfy({ $0.isWhitespace }) {
                    delegate?.blockParserDidReadInlineContent(in: range)
                }
            case .block(let block):
                delegate?.blockParserDidEnter(block: block)
                blockStack.append(block)
            }
        }

        // Update our new position
        currentOffset = line.upperBound
    }

    internal mutating func closeBlocks(from stackIndex: Int) {
        var closeBlockCount = blockStack[stackIndex...].indices.count

        while closeBlockCount > 0 {
            guard let closedBlock = blockStack.popLast() else {
                fatalError("Unexpected condition!")
            }

            delegate?.blockParserDidExit(block: closedBlock)
            closeBlockCount -= 1
        }
    }
}

public protocol NodeParserDelegate: class {
    func blockParserDidEnter(block: Node)
    func blockParserDidExit(block: Node)
    func blockParserDidReadInlineContent(in range: Range<Substring.Index>)
    func blockParserDidFinishParsing()
}

extension NodeParserDelegate {
    func blockParserDidFinishParsing() {}
}

public extension NodeParser {
    static let defaultMatchers: [NodeMatcher] = [
        Container.Matcher(variant: .blockquote),
        Container.Matcher(variant: .admonition),
        Heading.Matcher(),
        ThematicBreak.Matcher(),
        CodeBlock.Matcher(),
        Paragraph.Matcher()
    ]
}
