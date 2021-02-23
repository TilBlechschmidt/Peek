//
//  InlineParser.swift
//  
//
//  Created by Til Blechschmidt on 19.02.21.
//

import Foundation

public struct TokenReader {
    private let tokens: [Token]
    private(set) var currentIndex: Int

    init(tokens: [Token]) {
        self.tokens = tokens
        self.currentIndex = 0
    }
}

extension TokenReader {
    struct Error: Swift.Error {}

    var endIndex: Int { tokens.count }
    var didReachEnd: Bool { currentIndex == endIndex }

    var previousToken: Token? { lookBehind() }
    var currentToken: Token { tokens[currentIndex] }
    var nextToken: Token? { lookAhead() }
}

// MARK: - Token access
extension TokenReader {
    func tokens(since other: TokenReader) throws -> ArraySlice<Token> {
        let startIndex = other.currentIndex
        let endIndex = currentIndex
        guard startIndex < currentIndex else { throw Error() }
        return tokens[startIndex..<endIndex]
    }
}

// MARK: - Conditional reading
extension TokenReader {
    @discardableResult
    mutating func advance() throws -> Token {
        guard !didReachEnd else { throw Error() }
        let token = currentToken
        advanceIndex()
        return token
    }

    @discardableResult
    mutating func read(_ variant: Token.Variant) throws -> Token {
        guard !didReachEnd else { throw Error() }
        let token = currentToken

        guard token.variant == variant else { throw Error() }
        advanceIndex()

        return token
    }

    @discardableResult
    mutating func read(eitherOf variants: [Token.Variant]) throws -> Token {
        guard !didReachEnd else { throw Error() }
        let token = currentToken

        guard variants.contains(token.variant) else { throw Error() }
        advanceIndex()

        return token
    }

    @discardableResult
    mutating func readMultiple(of variants: [Token.Variant]) -> [Token] {
        var tokens: [Token] = []

        while !didReachEnd {
            if !variants.contains(currentToken.variant) {
                break
            }

            tokens.append(currentToken)
            advanceIndex()
        }

        return tokens
    }

    @discardableResult
    mutating func readCount(of variant: Token.Variant, upTo maximum: Int? = nil) -> Int {
        var count = 0

        while !didReachEnd {
            guard currentToken.variant == variant else { break }
            count += 1
            advanceIndex()

            if let maximum = maximum, count == maximum {
                return count
            }
        }

        return count
    }

    mutating func readUntil(encountering variant: Token.Variant, inclusive: Bool = true, allowEndOfFile: Bool = false) throws -> [Token] {
        try readUntil(encountering: [variant], inclusive: inclusive, allowEndOfFile: allowEndOfFile)
    }

    mutating func readUntil(encountering variants: [Token.Variant], inclusive: Bool = true, allowEndOfFile: Bool = false) throws -> [Token] {
        var tokens: [Token] = []

        while !didReachEnd {
            if !inclusive && variants.contains(currentToken.variant) {
                return tokens
            }

            tokens.append(currentToken)

            if inclusive && variants.contains(currentToken.variant) {
                advanceIndex()
                return tokens
            }

            advanceIndex()
        }

        if allowEndOfFile {
            return tokens
        } else {
            throw Error()
        }
    }

//    mutating func readUntil(encounteringSequence sequence: [Token.Variant], inclusive: Bool = true, allowEndOfFile: Bool = false) throws -> [Token] {
//        var sequenceIndex = 0
//        var tokens: [Token] = []
//
//        while !didReachEnd {
//            let foundTokens = try readUntil(encountering: sequence[sequenceIndex], inclusive: true, allowEndOfFile: allowEndOfFile)
//
//            tokens.append(contentsOf: foundTokens)
//
//            if foundTokens.last?.variant == .some(sequence[sequenceIndex]) {
//                sequenceIndex += 1
//            }
//
//            if sequenceIndex == sequence.count {
//                if !inclusive {
//                    // This is misleading! It could either be interpreted as "reverting" the reader or just removing it from the returned array
//                    tokens.removeLast(sequence.count)
//                }
//
//                return tokens
//            }
//        }
//
//        if allowEndOfFile {
//            return tokens
//        } else {
//            throw Error()
//        }
//    }

    mutating func readBlankLine(allowEndOfFile: Bool = false) throws {
        try read(.lineFeed)

        if didReachEnd {
            return
        }

        readCount(of: .whitespace)

        if didReachEnd {
            return
        }

        try read(.lineFeed)
    }

    mutating func consumeBlankLines() {
        while !didReachEnd {
            do {
                try readBlankLine(allowEndOfFile: true)
            } catch {
                break
            }
        }
    }

    mutating func attemptOrRewind<T>(_ mutation: (inout TokenReader) throws -> T) -> T? {
        let previousReader = self

        do {
            return try mutation(&self)
        } catch {
            self = previousReader
        }

        return nil
    }

    /// Advances to the next line, potentially up to the end of the file.
    /// If the encountered end of line is followed by a blank line, the returned Bool is set to true.
    /// Will practically never throw.
    mutating func advanceToNextLine() throws -> ([Token], Bool) {
        var tokens: [Token] = []

        let newTokens = try readUntil(encountering: .lineFeed, inclusive: false, allowEndOfFile: true)
        tokens.append(contentsOf: newTokens)

        if let _ = attemptOrRewind({ try $0.readBlankLine(allowEndOfFile: true) }) {
            return (tokens, true)
        } else if !didReachEnd {
            tokens.append(try advance())
        }

        return (tokens, false)
    }
}

// MARK: - Internals
private extension TokenReader {
    mutating func advanceIndex(by offset: Int = 1) {
        currentIndex += offset
    }

    func lookBehind() -> Token? {
        guard currentIndex != 0 else { return nil }
        return tokens[currentIndex - 1]
    }

    func lookAhead() -> Token? {
        guard !didReachEnd else { return nil }
        guard currentIndex + 1 != tokens.count else { return nil }
        return tokens[currentIndex + 1]
    }
}
