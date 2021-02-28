//
//  BlockAggregator.swift
//  
//
//  Created by Til Blechschmidt on 27.02.21.
//

import Foundation

public class BlockAggregator {
    private var referencedString: Substring
    private(set) var blocks: [Block] = []

    private var blockquote: Bool = false
    private var admonition: Bool = false

    private var pendingContent: [Range<Substring.Index>] = []
    private var pendingContentRange: Range<Substring.Index>? {
        guard let first = pendingContent.first, let last = pendingContent.last else {
            return nil
        }

        return first.lowerBound..<last.upperBound
    }

    public init(_ referencedString: Substring) {
        self.referencedString = referencedString
    }
}

extension BlockAggregator: NodeParserDelegate {
    public func blockParserDidEnter(block: Node) {
        if block.isEqual(to: Container(variant: .blockquote)) {
            blockquote = true
        } else if block.isEqual(to: Container(variant: .admonition)) {
            admonition = true
        } else if let thematicBreak = block as? ThematicBreak {
            blocks.append(Block(admonition: admonition, blockquote: blockquote, content: .thematicBreak(thematicBreak.variant)))
        } else if let code = block as? CodeBlock {
            blocks.append(Block(admonition: admonition, blockquote: blockquote, content: .code(language: String(referencedString[code.language]), content: String(referencedString[code.content]))))
        } else if block as? Heading != nil || block as? Paragraph != nil {
            pendingContent = []
        }
    }

    public func blockParserDidExit(block: Node) {
        if block.isEqual(to: Container(variant: .blockquote)) {
            blockquote = false
        } else if block.isEqual(to: Container(variant: .admonition)) {
            admonition = false
        } else if let heading = block as? Heading {
            blocks.append(Block(admonition: admonition, blockquote: blockquote, content: .heading(level: heading.level, content: pendingContentRange.map { String(referencedString[$0]) })))
        } else if block as? Paragraph != nil {
            blocks.append(Block(admonition: admonition, blockquote: blockquote, content: .text(String(referencedString[pendingContentRange!]))))
        }
    }

    public func blockParserDidReadInlineContent(in range: Range<Substring.Index>) {
        pendingContent.append(range)
    }

    public func blockParserDidFinishParsing() {
        print("Found \(blocks.count) blocks!")
    }
}
