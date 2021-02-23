//
//  ListItem+MarkdownConvertible.swift
//  
//
//  Created by Til Blechschmidt on 24.02.21.
//

import Foundation

extension ListItem: MarkdownConvertible {
    func markdownRepresentation(with serializedChildren: String) -> String {
        markdownMarker + serializedChildren
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "\n  ") + "\n"
    }

    private var markdownMarker: String {
        switch variant {
        case .ordered:
            return "1) "
        case .unordered:
            return "* "
        }
    }
}
