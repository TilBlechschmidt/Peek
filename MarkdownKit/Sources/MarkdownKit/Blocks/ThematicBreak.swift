//
//  ThematicBreak.swift
//
//
//  Created by Til Blechschmidt on 20.01.21.
//

import Foundation

struct ThematicBreak: Equatable {
    let variant: Variant

    enum Variant: Character {
        case dots = "*"
        case line = "-"
        case thickLine = "_"

        static var all: [Variant] = [.dots, .line, .thickLine]
    }
}

extension ThematicBreak: ReadableBlock {
    static func read(using reader: inout Reader) throws -> Self {
        let leadingWhitespaceCount = reader.discardWhitespaces()
        try require(leadingWhitespaceCount < 4)

        guard let variant = Variant(rawValue: reader.currentCharacter) else {
            throw Reader.Error()
        }

        try require(reader.readCount(of: variant.rawValue) > 2)
        try require(reader.readUntilEndOfLine().isEmpty)

        return ThematicBreak(variant: variant)
    }
}
