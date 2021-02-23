//
//  Heading+MarkdownConvertible.swift
//  
//
//  Created by Til Blechschmidt on 24.02.21.
//

import Foundation

extension Heading: MarkdownConvertible {
    func markdownRepresentation(with serializedChildren: String) -> String {
        String(repeating: "#", count: level) + " \(serializedChildren)"
    }
}
