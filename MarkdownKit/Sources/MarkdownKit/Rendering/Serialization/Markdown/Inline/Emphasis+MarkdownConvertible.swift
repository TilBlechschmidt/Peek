//
//  Emphasis+MarkdownConvertible.swift
//  
//
//  Created by Til Blechschmidt on 24.02.21.
//

import Foundation

extension Emphasis: MarkdownConvertible {
    func markdownRepresentation(with serializedChildren: String) -> String {
        let marker = Token.Variant.emphasis(variant).textRepresentation

        return marker + serializedChildren + marker
    }
}
