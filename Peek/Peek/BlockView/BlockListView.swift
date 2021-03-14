//
//  BlockView.swift
//  Peek
//
//  Created by Til Blechschmidt on 27.02.21.
//

import SwiftUI
import MarkdownKit

struct BlockListView: View {
//    @State var source: BlockSource
    @State var blocks: [Block]

    var body: some View {
        VStack(spacing: 0) {
            Button("Add", action: {
//                withAnimation(.easeIn) {
                for _ in 0..<10 {
                    blocks.append(Block(admonition: true, blockquote: false, content: .text("Hello!")))
                }
//                }
            })
            ForEach(blocks, id: \.id) { block in
                HStack {
                    OldBlockView(block: .init(get: { block }, set: { _ in }), onAppend: {
                        blocks.append(Block(admonition: true, blockquote: false, content: .text("Hello!")))
                    }, onDelete: {
                        blocks = blocks.filter { $0.id != block.id }
                    })
                        .padding(.horizontal)
                    Button("Delete", action: {
                        blocks = blocks.filter { $0.id != block.id }
//                        withAnimation(.easeIn) {
//                            source.removeBlock(withId: block.id)
//                        }
                    })
                }
            }
        }
    }
}

struct BlockListView_Previews: PreviewProvider {
    static var blocks = [
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
    ]

    static var previews: some View {
//        BlockListView(source: BlockSource(blocks: BlockListView_Previews.blocks))
        BlockListView(blocks: blocks)
        .previewLayout(PreviewLayout.fixed(width: 568, height: 600))
    }
}
