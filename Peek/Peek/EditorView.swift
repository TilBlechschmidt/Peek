//
//  EditorView.swift
//  Peek
//
//  Created by Til Blechschmidt on 19.02.21.
//

import SwiftUI
import UIKit

final class EditorView: UIViewRepresentable {
    typealias UIViewType = UITextView

    let textStorage = FancyTextStorage()

    func makeUIView(context: Context) -> UITextView {
        let attrs = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)]
        let attrString = NSAttributedString(string: "Hello *world*!", attributes: attrs)
        textStorage.append(attrString)

        let layoutManager = NSLayoutManager()
        let containerSize = CGSize(width: Double(300), height: .greatestFiniteMagnitude)
        let container = NSTextContainer(size: containerSize)
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)
        textStorage.addLayoutManager(layoutManager)

        let view = UITextView(frame: .zero, textContainer: container)
        view.textColor = .white
        view.backgroundColor = .clear
        view.delegate = textStorage
//        view.allowsEditingTextAttributes = true

        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Miep
    }
}
