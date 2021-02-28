//
//  BlockTextContentView.swift
//  Peek
//
//  Created by Til Blechschmidt on 28.02.21.
//

import SwiftUI

struct BlockTextContentView: View {
    @State var text: String

    let editable: Bool = true
    let onCommit: (String) -> Void

    var body: some View {
        EditorView(text: $text, editable: editable, onCommit: onCommit)
            .padding()
    }
}

struct BlockTextContentView_Previews: PreviewProvider {
    static var previews: some View {
        BlockTextContentView(text: "Hello world!", onCommit: { _ in })
    }
}
