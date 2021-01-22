//
//  Paragraph.swift
//  
//
//  Created by Til Blechschmidt on 20.01.21.
//

import Foundation

struct Paragraph: Equatable {
    let text: Substring
}

extension Paragraph: ReadableBlock {
    static func read(using reader: inout Reader) throws -> Paragraph {
        Paragraph(text: reader.readUntilBlankLine())
    }
}
