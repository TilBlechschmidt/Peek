//
//  BlockView.swift
//  Peek
//
//  Created by Til Blechschmidt on 27.02.21.
//

import SwiftUI
import MarkdownKit

extension Block {
    struct Connection: OptionSet {
        let rawValue: Int

        static let previous = Connection(rawValue: 1 << 0)
        static let next     = Connection(rawValue: 1 << 1)

        var edgesRequiringPadding: Edge.Set {
            var set: Edge.Set = []

            if !contains(.previous) {
                set.insert(.top)
            }

            if !contains(.next) {
                set.insert(.bottom)
            }

            return set
        }

        var cornersWithRadius: UIRectCorner {
            var set: UIRectCorner = []

            if !contains(.previous) {
                set.insert(.topLeft)
                set.insert(.topRight)
            }

            if !contains(.next) {
                set.insert(.bottomLeft)
                set.insert(.bottomRight)
            }

            return set
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct OldBlockView: View {
    let cornerRadius: CGFloat = 5
    let connection: Block.Connection = []

    @Binding var block: Block

    let onAppend: () -> Void
    let onDelete: () -> Void

    var contentBinding: Binding<Block.Content> {
        Binding(get: { block.content }, set: { newContent in
            block = block.replacingContent(with: newContent)
        })
    }

    var body: some View {
        HStack {
            BlockContentView(content: contentBinding, onAppend: onAppend, onDelete: onDelete)
                .padding(block.blockquote ? connection.edgesRequiringPadding.union(.leading) : [])
                .background(
                    Rectangle()
                        .cornerRadius(cornerRadius, corners: connection.cornersWithRadius)
                        .foregroundColor(Color.blockquote)
                        .opacity(block.blockquote ? 1 : 0)
                        .padding(connection.edgesRequiringPadding.union(.leading)))
                .background(
                    Rectangle()
                        .cornerRadius(cornerRadius, corners: connection.cornersWithRadius)
                        .foregroundColor(.accentColor)
                        .frame(width: block.admonition ? 5 : 0)
                        .padding(connection.edgesRequiringPadding, 8),
                    alignment: .leading)
        }
    }
}

//struct BlockView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            BlockView(block: .constant(Block(admonition: false, blockquote: false, content: .text("Hello world!"))))
//            BlockView(block: .constant(Block(admonition: true, blockquote: false, content: .text("Hello world!"))))
//            BlockView(block: .constant(Block(admonition: false, blockquote: true, content: .text("Hello world!"))))
//            BlockView(block: .constant(Block(admonition: true, blockquote: true, content: .text("Hello world!"))))
//            BlockView(block: .constant(Block(admonition: true, blockquote: false, content: .thematicBreak(.dots))))
//        }.padding().previewLayout(PreviewLayout.fixed(width: 568, height: 100))
//    }
//}
