//
//  EditorView.swift
//  Peek
//
//  Created by Til Blechschmidt on 19.02.21.
//

import SwiftUI
import UIKit

//struct EditorView: UIViewRepresentable {
//    typealias UIViewType = UITextView
//
//    let textStorage = FancyTextStorage()
//
//    @Binding var text: String
//
//    let editable: Bool
//    let textStyle: UIFont.TextStyle = .body
//
//    let onCommit: ((String) -> Void)?
//    let onDelete: (() -> Void)?
//    let onAppend: (() -> Void)?
//
//    func makeUIView(context: Context) -> UITextView {
//        let layoutManager = NSLayoutManager()
//        let container = NSTextContainer(size: .zero)
//        container.widthTracksTextView = true
//        layoutManager.addTextContainer(container)
//        textStorage.addLayoutManager(layoutManager)
//
//        let textView = BlockTextView(frame: .zero, textContainer: container)
//        textView.textColor = .label
//        textView.backgroundColor = .clear
//
//        textView.font = UIFont.preferredFont(forTextStyle: textStyle)
//
//        textView.isScrollEnabled = false
//        textView.alwaysBounceVertical = false
//        textView.isUserInteractionEnabled = true
//
//        textView.contentInset = .zero
//        textView.textContainerInset = .zero
//        textView.textContainer.lineFragmentPadding = 0
//
//        context.coordinator.textView = textView
//        textView.delegate = context.coordinator
//        textView.inlineDelegate = context.coordinator
//
//        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//
//        // iOS renders things in a different order
//        // Due to that, our intrinsicContentSize override is not queried anymore
//        // after the view width has been set. Thus we need to invalidate it
//        // once the initial rendering is completed.
//        DispatchQueue.main.async {
//            textView.invalidateIntrinsicContentSize()
//        }
//
////        view.enablesReturnKeyAutomatically = true
////        view.allowsEditingTextAttributes = true
////
////        let textViewToolbar: UIToolbar = UIToolbar()
////        textViewToolbar.barStyle = .default
////        textViewToolbar.items = [
////            UIBarButtonItem(title: "Cancel", style: .done,
////                      target: self, action: #selector(cancelInput)),
////            UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
////                      target: self, action: nil),
////            UIBarButtonItem(title: "Post Reply", style: .done,
////                      target: self, action: #selector(cancelInput))
////        ]
////        textViewToolbar.sizeToFit()
////        view.inputAccessoryView = textViewToolbar
//
////        let fixedWidth = textView.frame.size.width
////        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
////        textView.frame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
//
//        return textView
//    }
//
//    func updateUIView(_ uiView: UITextView, context: Context) {
//        uiView.text = text
//        uiView.isEditable = editable
//        uiView.isSelectable = editable
////        uiView.invalidateIntrinsicContentSize()
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    class Coordinator: NSObject, UITextViewDelegate, BlockTextViewDelegate {
//        func deleteParagraph() {
//            // TODO
//        }
//
//        func appendParagraphBelow() {
//            // TODO
//        }
//
//        func goToPreviousParagraph(at offset: CGFloat) {
//            // TODO
//        }
//
//        func goToNextParagraph(at offset: CGFloat) {
//            // TODO
//        }
//
//        func goToBeginningOfDocument() {
//            // TODO
//        }
//
//        func goToEndOfDocument() {
//            // TODO
//        }
//
//        func selectToBeginningOfDocument() {
//            // TODO
//        }
//
//        func selectToEndOfDocument() {
//            // TODO
//        }
//
//        func selectThisAndPreviousBlock() {
//            // TODO
//        }
//
//        func selectThisAndNextBlock() {
//            // TODO
//        }
//
//        let editorView: EditorView
//        weak var textView: UITextView?
//
//        init(_ view: EditorView) {
//            editorView = view
//        }
//
//        func textViewDidChange(_ textView: UITextView) {
//            editorView.text = textView.text
//        }
//
//        func textViewDidEndEditing(_ textView: UITextView) {
//            editorView.onCommit?(textView.text)
//        }
//
//        func textViewDidChangeSelection(_ textView: UITextView) {
//            editorView.textStorage.textViewDidChangeSelection(textView)
//        }
//
//        func textViewDidReceiveDeletionRequest() {
//            editorView.onDelete?()
//        }
//
//        func textViewDidReceiveNextParagraphRequest() {
//            editorView.onAppend?()
//        }
//    }
//}
