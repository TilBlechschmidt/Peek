//
//  CodeBlock.swift
//  
//
//  Created by Til Blechschmidt on 22.01.21.
//

import Foundation

struct CodeBlock: Equatable {
    let variant: Variant
    let delimiterCount: Int
    let infoString: Substring
    let code: Substring

    enum Variant: Character {
        case tilde = "~"
        case backtick = "`"

        static var all: [Variant] = [.tilde, .backtick]
    }
}

extension CodeBlock: ReadableBlock {
    static func read(using reader: inout Reader) throws -> Self {
        guard let variant = Variant(rawValue: reader.currentCharacter) else {
            throw Reader.Error()
        }

        let delimiterCount = reader.readCount(of: variant.rawValue)
        try require(delimiterCount > 2)
        let infoString = reader.readUntilEndOfLine()

        if variant == .backtick {
            try require(!infoString.contains(variant.rawValue))
        }

        let closeString = "\n\(String(repeating: variant.rawValue, count: delimiterCount))"
        let code = reader.readUntilEncountering(terminator: closeString)

        return CodeBlock(variant: variant, delimiterCount: delimiterCount, infoString: infoString, code: code)
    }
}
