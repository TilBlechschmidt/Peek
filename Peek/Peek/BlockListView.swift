//
//  BlockView.swift
//  Peek
//
//  Created by Til Blechschmidt on 27.02.21.
//

import SwiftUI
import MarkdownKit

struct BlockListView: View {
    let blocks: [Block]

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(blocks, id: \.id) { block in
                BlockView(block: block).padding(.horizontal)
            }
        }
    }
}

struct BlockListView_Previews: PreviewProvider {
    static var previews: some View {
        BlockListView(blocks: [
            Block(admonition: false, blockquote: false, content: .heading(level: 1, content: "Super important heading")),
//            Block(admonition: false, blockquote: false, content: .heading(level: 2, content: "Super important heading")),
//            Block(admonition: false, blockquote: false, content: .heading(level: 3, content: "Super important heading")),
//            Block(admonition: false, blockquote: false, content: .heading(level: 4, content: "Super important heading")),
//            Block(admonition: false, blockquote: false, content: .heading(level: 5, content: "Super important heading")),
//            Block(admonition: false, blockquote: false, content: .heading(level: 6, content: "Super important heading")),
            // swiftlint:disable:next line_length
            Block(admonition: false, blockquote: false, content: .text("This is a wonderful and lovely test document! How about you do some research about what you can do?")),
            Block(admonition: false, blockquote: false, content: .thematicBreak(.dots)),
            // swiftlint:disable:next line_length
            Block(admonition: false, blockquote: false, content: .text("Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.")),
            Block(admonition: true, blockquote: false, content: .text("Hello world!")),
            Block(admonition: false, blockquote: true, content: .text("Hello world!")),
            Block(admonition: true, blockquote: true, content: .text("Hello world!"))
        ])
        .previewLayout(PreviewLayout.fixed(width: 568, height: 600))
    }
}
