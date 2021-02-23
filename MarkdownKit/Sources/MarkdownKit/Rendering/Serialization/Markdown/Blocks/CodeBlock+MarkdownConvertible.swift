//
//  CodeBlock+MarkdownConvertible.swift
//  
//
//  Created by Til Blechschmidt on 24.02.21.
//

import Foundation

extension CodeBlock: MarkdownConvertible {
    func markdownRepresentation(with serializedChildren: String) -> String {
        let surroundingBackticks = String(repeating: "`", count: max(3, numberOfConsecutive(occurencesOf: "`", in: serializedChildren) + 1))

        var serializedChildren = serializedChildren
        if serializedChildren.last != "\n" {
            serializedChildren += "\n"
        }

        return surroundingBackticks + "\(language)\n" + serializedChildren + surroundingBackticks + "\n"
    }
}
