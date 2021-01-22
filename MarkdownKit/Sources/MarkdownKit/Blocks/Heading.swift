//
//  Heading.swift
//  
//
//  Created by Til Blechschmidt on 20.01.21.
//

import Foundation

struct Heading: Equatable {
    let level: Int
    let rawContent: Substring
}

extension Heading: ReadableBlock {
    static func read(using reader: inout Reader) throws -> Self {
        let level = reader.readCount(of: "#")
        try require(level > 0 && level < 7)
        try reader.readWhitespaces()

        return Heading(level: level, rawContent: reader.readUntilEndOfLine())
    }
}
