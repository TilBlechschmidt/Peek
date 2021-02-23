//
//  List+MarkdownConvertible.swift
//  
//
//  Created by Til Blechschmidt on 24.02.21.
//

import Foundation

extension List: MarkdownConvertible {
    func markdownRepresentation(with serializedChildren: String) -> String {
        serializedChildren
    }
}
