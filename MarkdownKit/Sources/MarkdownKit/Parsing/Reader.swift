//
//  File.swift
//  
//
//  Created by Til Blechschmidt on 20.01.21.
//

import Foundation

internal struct Reader {
    private let string: String
    private(set) var currentIndex: String.Index

    init(string: String) {
        self.string = string
        self.currentIndex = string.startIndex
    }
}

// MARK: - Utilities
extension Reader {
    struct Error: Swift.Error {}

    var didReachEnd: Bool { currentIndex == endIndex }
    var previousCharacter: Character? { lookBehindAtPreviousCharacter() }
    var currentCharacter: Character { string[currentIndex] }
    var nextCharacter: Character? { lookAheadAtNextCharacter() }
    var endIndex: String.Index { string.endIndex }
}

// MARK: - Conditional reading
extension Reader {
    mutating func read(_ character: Character) throws {
        guard !didReachEnd else { throw Error() }
        guard currentCharacter == character else { throw Error() }
        advanceIndex()
    }

    mutating func readCount(of character: Character) -> Int {
        var count = 0

        while !didReachEnd {
            guard currentCharacter == character else { break }
            count += 1
            advanceIndex()
        }

        return count
    }

    @discardableResult
    mutating func readCharacters(matching keyPath: KeyPath<Character, Bool>,
                                 max maxCount: Int = Int.max) throws -> Substring {
        let startIndex = currentIndex
        var count = 0

        while !didReachEnd
              && count < maxCount
              && currentCharacter[keyPath: keyPath] {
            advanceIndex()
            count += 1
        }

        guard startIndex != currentIndex else {
            throw Error()
        }

        return string[startIndex..<currentIndex]
    }

    @discardableResult
    mutating func readCharacter(in set: Set<Character>) throws -> Character {
        guard !didReachEnd else { throw Error() }
        guard set.contains(currentCharacter) else { throw Error() }
        defer { advanceIndex() }

        return currentCharacter
    }

    @discardableResult
    mutating func readWhitespaces() throws -> Substring {
        try readCharacters(matching: \.isSameLineWhitespace)
    }

    mutating func readUntilEndOfLine(includeNewline: Bool = false) -> Substring {
        let startIndex = currentIndex

        while !didReachEnd {
            guard !currentCharacter.isNewline else {
                if includeNewline { advanceIndex() }
                let text = string[startIndex..<currentIndex]
                if !includeNewline { advanceIndex() }
                return text
            }

            advanceIndex()
        }

        return string[startIndex..<currentIndex]
    }

    mutating func readUntilBlankLine() -> Substring {
        let startIndex = currentIndex
        var previousLineIndex = startIndex

        while !didReachEnd {
            let line = readUntilEndOfLine()
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                break
            }

            previousLineIndex = line.endIndex
        }

        return string[startIndex..<previousLineIndex]
    }

    mutating func readUntilEncountering(terminator: String) -> Substring {
        let startIndex = currentIndex
        var terminatorIndex = terminator.startIndex

        while !didReachEnd {
            if currentCharacter != terminator[terminatorIndex] {
                terminatorIndex = terminator.startIndex
            }

            if currentCharacter == terminator[terminatorIndex] {
                terminatorIndex = terminator.index(after: terminatorIndex)
            }

            advanceIndex()

            if terminatorIndex == terminator.endIndex {
                return string[startIndex..<string.index(currentIndex, offsetBy: -terminator.count)]
            }
        }

        return string[startIndex..<currentIndex]
    }

    @discardableResult
    mutating func discardWhitespaces() -> Int {
        var count = 0

        while !didReachEnd {
            guard currentCharacter.isSameLineWhitespace else { return count }
            advanceIndex()
            count += 1
        }

        return count
    }

    mutating func discardWhitespacesAndNewlines() {
        while !didReachEnd {
            guard currentCharacter.isWhitespace else { return }
            advanceIndex()
        }
    }
}

// MARK: - Index manipulation
extension Reader {
    mutating func advanceIndex(by offset: Int = 1) {
        currentIndex = string.index(currentIndex, offsetBy: offset)
    }

    mutating func rewindIndex() {
        currentIndex = string.index(before: currentIndex)
    }

    mutating func moveToIndex(_ index: String.Index) {
        currentIndex = index
    }
}

// MARK: - Internals
private extension Reader {
    func lookBehindAtPreviousCharacter() -> Character? {
        guard currentIndex != string.startIndex else { return nil }
        let previousIndex = string.index(before: currentIndex)
        return string[previousIndex]
    }

    func lookAheadAtNextCharacter() -> Character? {
        guard !didReachEnd else { return nil }
        let nextIndex = string.index(after: currentIndex)
        guard nextIndex != string.endIndex else { return nil }
        return string[nextIndex]
    }
}

internal extension Character {
    var isSameLineWhitespace: Bool {
        isWhitespace && !isNewline
    }
}
