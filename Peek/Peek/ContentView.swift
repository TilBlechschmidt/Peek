//
//  ContentView.swift
//  Peek
//
//  Created by Til Blechschmidt on 19.02.21.
//

import SwiftUI
import MarkdownKit

struct ContentView: View {
    var body: some View {
        VStack {
            ScrollView {
                BlockListView(blocks: [
                    Block(admonition: false, blockquote: false, content: .heading(level: 1, content: "Super important heading")),
                    // swiftlint:disable:next line_length
                    Block(admonition: false, blockquote: false, content: .text("This is a wonderful and lovely test document! How about you do some research about what you can do?")),
                    Block(admonition: false, blockquote: false, content: .thematicBreak(.dots)),
                    // swiftlint:disable:next line_length
                    Block(admonition: false, blockquote: false, content: .text("Here is some more seemingly random text! Have fun with it. Because I am really lost on what to write about. However, for testing purposes I do need more content so realistically, I will just keep writing.")),
                    Block(admonition: true, blockquote: false, content: .text("Hello world!")),
                    Block(admonition: false, blockquote: true, content: .text("Hello world!")),
                    Block(admonition: true, blockquote: true, content: .text("Hello world!"))
                ])
                    .padding()
                    .frame(maxWidth: 800)
                    .withHostingWindow { window in
                        #if targetEnvironment(macCatalyst)
                        if let titlebar = window?.windowScene?.titlebar {
                            titlebar.titleVisibility = .hidden
                            titlebar.toolbar = nil
                        }
                        #endif
                    }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension View {
    fileprivate func withHostingWindow(_ callback: @escaping (UIWindow?) -> Void) -> some View {
        self.background(HostingWindowFinder(callback: callback))
    }
}

private struct HostingWindowFinder: UIViewRepresentable {
    var callback: (UIWindow?) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async { [weak view] in
            self.callback(view?.window)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
