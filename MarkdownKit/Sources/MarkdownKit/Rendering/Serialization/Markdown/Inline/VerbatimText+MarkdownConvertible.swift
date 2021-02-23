//
//  VerbatimText+MarkdownConvertible.swift
//  
//
//  Created by Til Blechschmidt on 24.02.21.
//

import Foundation

extension VerbatimText: MarkdownConvertible {
    func markdownRepresentation(with serializedChildren: String) -> String {
        self.content.textRepresentation
    }
}
