//
//  InlineParser.swift
//  
//
//  Created by Til Blechschmidt on 26.02.21.
//

import Foundation

struct DelimiterRun {
    struct Flanking: OptionSet {
        let rawValue: Int

        static var left  = Flanking(rawValue: 1 << 0)
        static var right = Flanking(rawValue: 1 << 1)

        static var both: Flanking = [.left, .right]
    }

    let flanking: Flanking
    let variant: Character

    private(set) var range: Range<Substring.Index>
    private(set) var count: Int

    init(_ variant: Character, from string: Substring, previousCharacter: Character?) {
        var flanking: Flanking = []

        let upperBound = string.firstIndex(where: { $0 != variant }) ?? string.endIndex

        // Some variable definitions for flanking checks
        let followedByWhitespace = upperBound == string.endIndex || string[upperBound].isWhitespace
        let followedByPunctuation = upperBound != string.endIndex && string[upperBound].isPunctuation
        let precededByWhitespace = previousCharacter?.isWhitespace ?? true
        let precededByPunctuation = previousCharacter?.isPunctuation ?? false

        // Check if we are left-flanking
        // (1) not followed .whitespace, and either
        //      (2a) not followed .punctuation,
        //   or (2b) followed by .punctuation and preceded by (.whitespace || .punctuation)
        if !followedByWhitespace && (!followedByPunctuation || (followedByPunctuation && (precededByWhitespace || precededByPunctuation))) {
            flanking.insert(.left)
        }

        // Check if we are right-flanking
        // (1) not preceded by .whitespace, and either
        //      (2a) not preceded by .punctuation,
        //   or (2b) preceded by .punctuation and followed by (.whitespace || .punctuation)
        if !precededByWhitespace && (!precededByPunctuation || (precededByPunctuation && (followedByWhitespace || followedByPunctuation))) {
            flanking.insert(.right)
        }

        self.flanking = flanking
        self.variant = variant
        self.range = string.startIndex..<upperBound
        self.count = string[range].count
    }

    mutating func remove(_ countToRemove: Int, in string: Substring, left: Bool) -> Range<Substring.Index> {
        count -= countToRemove

        if left {
            let newLowerBound = string.index(range.lowerBound, offsetBy: countToRemove)
            let removedRange = range.lowerBound..<newLowerBound
            range = newLowerBound..<range.upperBound
            return removedRange
        } else {
            let newUpperBound = string.index(range.upperBound, offsetBy: -countToRemove)
            let removedRange = newUpperBound..<range.upperBound
            range = range.lowerBound..<newUpperBound
            return removedRange
        }
    }
}

public struct Emphasis: Hashable {
    public let opener: Range<Substring.Index>
    public let closer: Range<Substring.Index>
    public let content: Range<Substring.Index>

    public let variant: Character
    public let strength: Int

    public var range: Range<Substring.Index> {
        opener.lowerBound..<closer.upperBound
    }
}

public protocol InlineParserDelegate: class {
    func inlineParserDidEncounter(emphasis: Emphasis)
    func inlineParserDidFinishParsing()
}

extension InlineParserDelegate {
    public func inlineParserDidFinishParsing() {}
}

public struct InlineParser {
    public let input: Substring
    public weak var delegate: InlineParserDelegate? = nil

    public init(_ input: Substring) {
        self.input = input
    }

    private func buildStack() -> LinkedList<DelimiterRun> {
        var stack = LinkedList<DelimiterRun>()
        var iterator = zip(input.indices, input).makeIterator()
        var previousIndex: Substring.Index? = nil

        let addDelimiterRun = { (substring: Substring, variant: Character) in
            let previousCharacter = previousIndex.map({ input[$0] })
            let run = DelimiterRun(variant, from: substring, previousCharacter: previousCharacter)
            let remainingInput = input[run.range.upperBound...]

            iterator = zip(remainingInput.indices, remainingInput).makeIterator()
            previousIndex = input.index(before: run.range.upperBound)
            stack.append(run)
        }

        while let (index, character) = iterator.next() {
            switch character {
            case "*":
                addDelimiterRun(input[index...], "*")
            case "_":
                addDelimiterRun(input[index...], "_")
            case "~":
                addDelimiterRun(input[index...], "~")
            case "=":
                addDelimiterRun(input[index...], "=")
            default:
                previousIndex = index
            }
        }

        return stack
    }

    public func start() {
        var stack = buildStack()
        let stackBottom: LinkedList<DelimiterRun>.Node? = nil
        var currentPosition = stackBottom?.next ?? stack.head
        var openersBottom: [Character : LinkedList<DelimiterRun>.Node?] = [
            "*": stackBottom,
            "_": stackBottom,
            "~": stackBottom,
            "=": stackBottom
        ]

        while let closer = currentPosition {
            // Look for the first potential closer in the stack (in parsing direction)
            let run = closer.item
            if run.flanking.contains(.right) {
                // Disallow highlight with only one =
                let allowed = run.variant != "=" || run.count % 2 == 0

                // Go back to find the first potential opener
                if allowed, let opener = findPotentialOpeningDelimiter(closer, run.variant, stayingAbove: openersBottom[run.variant]!) {
                    removeDelimitersBetween(start: opener, end: closer, in: &stack)

                    let strength = opener.item.count >= 2 && run.count >= 2 ? 2 : 1
                    let contentRange = opener.item.range.upperBound..<closer.item.range.lowerBound
                    let openerDelimiterRange = reduce(opener, by: strength, in: &stack, false)
                    let closerDelimiterRange = reduce(closer, by: strength, in: &stack, true)
                    let emphasis = Emphasis(opener: openerDelimiterRange, closer: closerDelimiterRange, content: contentRange, variant: run.variant, strength: strength)
                    delegate?.inlineParserDidEncounter(emphasis: emphasis)

                    if closer.item.count == 0 {
                        currentPosition = closer.next
                    }
                } else {
                    openersBottom[run.variant] = closer.prev
                    // Remove the closer from the stack if it can not be an opener
                    if !run.flanking.contains(.left) {
                        stack.remove(node: closer)
                    }

                    currentPosition = closer.next
                }
            } else {
                currentPosition = closer.next
            }
        }

        delegate?.inlineParserDidFinishParsing()
    }

    private func reduce(_ run: LinkedList<DelimiterRun>.Node, by count: Int, in stack: inout LinkedList<DelimiterRun>, _ left: Bool) -> Range<Substring.Index> {
        let range = run.item.remove(count, in: input, left: left)

        if run.item.count == 0 {
            stack.remove(node: run)
        }

        return range
    }

    private func removeDelimitersBetween(start: LinkedList<DelimiterRun>.Node, end: LinkedList<DelimiterRun>.Node, in stack: inout LinkedList<DelimiterRun>) {
        var node = start
        while let position = node.next {
            if position === end {
                break
            }

            stack.remove(node: position)

            node = position
        }
    }

    private func findPotentialOpeningDelimiter(_ closer: LinkedList<DelimiterRun>.Node, _ variant: Character, stayingAbove lowerLimit: LinkedList<DelimiterRun>.Node?) -> LinkedList<DelimiterRun>.Node? {
        var currentPosition: LinkedList<DelimiterRun>.Node? = closer

        while let position = currentPosition {
            if position === lowerLimit {
                break
            }

            let run = position.item
            let allowed = run.variant != "=" || run.count % 2 == 0
            if allowed && closer !== position && run.variant == variant && run.flanking.contains(.left) {
                return currentPosition
            }

            currentPosition = currentPosition?.prev
        }

        return nil
    }
}

struct LinkedList<E> {
    private(set) var head: Node? = nil
    private(set) var tail: Node? = nil

    var firstItem: E? {
        head?.item
    }

    var lastItem: E? {
        head?.item
    }

    mutating func append(_ item: E) {
        let node = Node(item, prev: tail)
        tail?.next = node
        tail = node

        if head == nil {
            head = tail
        }
    }

    mutating func prepend(_ item: E) {
        let node = Node(item, next: head)
        head?.prev = node
        head = node

        if tail == nil {
            tail = head
        }
    }

    mutating func remove(node: Node) {
        if head === node {
            head = node.next
        }

        if tail === node {
            tail = node.prev
        }

        node.prev?.next = node.next
        node.next?.prev = node.prev
    }
}

extension LinkedList {
    class Node {
        var prev: Node?
        var next: Node?

        var item: E

        init(_ item: E, prev: Node? = nil, next: Node? = nil) {
            self.item = item
            self.prev = prev
            self.next = next
        }
    }
}

extension LinkedList: Sequence {
    class Iterator: IteratorProtocol {
        typealias Element = E

        var node: Node?

        init(_ node: Node?) {
            self.node = node
        }

        func next() -> E? {
            let item = node?.item
            node = node?.next
            return item
        }
    }

    func makeIterator() -> Iterator {
        Iterator(head)
    }
}

// Support syntax:
//    _italics
//    *italics*
//    __bold__
//    **bold**
//    ~underline~
//    ~~strikethrough~~
//    ==highlighter==
//    `code span`
//    [[wikiLink]]
//    ![[wiki.embed]]
//    [normal](web.link)
//    ![normal](embed.link)
// => Delimiter stack contents:
// Run of either: * ~ = _
// Occurence of: ![ or [
