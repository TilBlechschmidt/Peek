//
//  TextContentBlock.swift
//  Peek
//
//  Created by Til Blechschmidt on 18.04.21.
//

import Foundation

class TextContentBlock: ContentBlock {
    @Published var text: String

    init(_ id: UUID = UUID(), text: String) {
        self.text = text
        super.init(id)
    }

    override func canIntegrate(content other: ContentBlock) -> Bool {
        return other as? TextContentBlock != nil
    }

    override func integrate(content other: ContentBlock) {
        if let textContent = other as? TextContentBlock {
            text += textContent.text
        } else {
            super.integrate(content: other)
        }
    }

    override func extractTrailingContent(_ cell: BlockEditorCell) -> ContentBlock? {
        if let textCell = cell as? TextBlockEditorCell {
            let selection = textCell.selection

            // Define the ranges
            let trailingRange = text.index(text.startIndex, offsetBy: selection.upperBound)..<text.endIndex
            let purgeRange = text.index(text.startIndex, offsetBy: selection.lowerBound)..<text.endIndex

            // Extract and purge the content from self
            let trailingContent = text[trailingRange]
            text.removeSubrange(purgeRange)

            // Build a new Block
            return TextContentBlock(text: String(trailingContent))
        } else {
            return super.extractTrailingContent(cell)
        }
    }

    override func serializeForDrag() -> NSItemProvider {
        NSItemProvider(object: text as NSString)
    }
}
