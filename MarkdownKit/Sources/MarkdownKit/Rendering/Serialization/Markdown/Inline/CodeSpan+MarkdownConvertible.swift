//
//  CodeSpan+MarkdownConvertible.swift
//  
//
//  Created by Til Blechschmidt on 24.02.21.
//

import Foundation

extension CodeSpan: MarkdownConvertible {
    func markdownRepresentation(with serializedChildren: String) -> String {
        let surroundingBackticks = String(repeating: "`", count: max(1, numberOfConsecutive(occurencesOf: "`", in: serializedChildren) + 1))

        return surroundingBackticks + serializedChildren + surroundingBackticks
    }
}

internal func numberOfConsecutive(occurencesOf character: Character, in string: String) -> Int {
    var maximum = 0
    var current = 0

    for c in string {
        if c == character {
            current += 1
        } else if current > maximum {
            maximum = current
            current = 0
        } else {
            current = 0
        }
    }

    return max(current, maximum)
}
