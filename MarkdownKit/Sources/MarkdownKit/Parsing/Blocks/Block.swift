//
//  Block.swift
//  
//
//  Created by Til Blechschmidt on 27.02.21.
//

import Foundation

public struct Block: Identifiable {
    public let id: UUID

    public let admonition: Bool
    public let blockquote: Bool

    public let content: Content

    public enum Content {
        case thematicBreak(ThematicBreak.Variant)
        case heading(level: Int, content: String?)
        case code(language: String, content: String)
        case text(String)
    }

    public init(id: UUID = UUID(), admonition: Bool, blockquote: Bool, content: Block.Content) {
        self.id = id
        self.admonition = admonition
        self.blockquote = blockquote
        self.content = content
    }
}
