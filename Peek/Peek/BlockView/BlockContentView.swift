//
//  BlockContentView.swift
//  Peek
//
//  Created by Til Blechschmidt on 27.02.21.
//

import SwiftUI
import MarkdownKit

extension View {
    func heading(level: Int) -> some View {
        let padding = (7.0 - CGFloat(level)) * 5.0
        var fontVariant: Font = .body

        switch level {
        case 1:
            fontVariant = .title
        case 2:
            fontVariant = .title2
        case 3:
            fontVariant = .title3
        case 4:
            fontVariant = .headline
        case 5:
            fontVariant = Font.headline.lowercaseSmallCaps()
        case 6:
            fontVariant = Font.body.bold()
        default:
            fontVariant = .body
        }

        return font(fontVariant).padding(.top, padding)
    }
}

struct BlockContentView: View {
    @Binding var content: Block.Content

    let onAppend: () -> Void
    let onDelete: () -> Void

    var body: some View {
        switch content {
        case .text(let text):
            BlockTextContentView(text: text, onCommit: { content = .text($0) }, onAppend: onAppend, onDelete: onDelete)
        case .heading(let level, let text):
            HStack {
                Text(text ?? "").heading(level: level)
                Spacer()
            }.padding()
        case .thematicBreak(let variant):
            switch variant {
            case .dots:
                HStack(spacing: 12) {
                    Spacer()
                    ForEach(0..<3) { _ in
                        // TODO This color looks ever so slightly off on light mode
                        Circle().foregroundColor(.gray).frame(width: 3, height: 3)
                    }
                    Spacer()
                }.padding().frame(height: 50)
            case .line:
                // TODO This color looks ever so slightly off on light mode
                Rectangle().foregroundColor(.gray).frame(height: 0.5).padding(.horizontal).frame(height: 50)
            case .thickLine:
                // TODO This color does not work on light mode
                Rectangle().foregroundColor(.white).frame(height: 1.5).padding(.horizontal).frame(height: 50)
            }
        default:
            Text("Unknown block type")
        }
    }
}

//struct BlockContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            BlockContentView(content: .constant(.heading(level: 1, content: "Why this app is cool")))
//            BlockContentView(content: .constant(.text("Hello world!")))
//            BlockContentView(content: .constant(.thematicBreak(.dots)))
//            BlockContentView(content: .constant(.thematicBreak(.line)))
//            BlockContentView(content: .constant(.thematicBreak(.thickLine)))
//        }.previewLayout(PreviewLayout.fixed(width: 568, height: 100))
//    }
//}
