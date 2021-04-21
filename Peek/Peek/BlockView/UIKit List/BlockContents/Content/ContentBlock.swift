//
//  ContentBlock.swift
//  Peek
//
//  Created by Til Blechschmidt on 18.04.21.
//

import Foundation

class ContentBlock: Identifiable {
    let id: UUID

    init(_ id: UUID = UUID()) {
        self.id = id
    }

    // -- Methods and fields to be overidden by subclasses

    func canIntegrate(content other: ContentBlock) -> Bool {
        false
    }

    func integrate(content other: ContentBlock) {
        fatalError("Attempted to integrate incompatible content!")
    }

    func extractTrailingContent(_ cell: BlockEditorCell) -> ContentBlock? {
        return nil
    }

    func serializeForDrag() -> NSItemProvider {
        fatalError("Attempted to serialize non-serializable block!")
    }
}
