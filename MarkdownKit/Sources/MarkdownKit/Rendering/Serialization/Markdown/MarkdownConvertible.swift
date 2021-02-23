//
//  MarkdownConvertible.swift
//  
//
//  Created by Til Blechschmidt on 24.02.21.
//

import Foundation

protocol MarkdownConvertible: NodeVariant {
    func markdownRepresentation(with serializedChildren: String) -> String
}

extension Node {
    func markdownRepresentation() throws -> String {
        let serializedChildren = try children.map { try $0.markdownRepresentation() }

        guard let variant = self.variant as? MarkdownConvertible else {
            throw SerializationError.childNotSerializable(self.variant)
        }

        return variant.markdownRepresentation(with: serializedChildren.joined())
    }
}
