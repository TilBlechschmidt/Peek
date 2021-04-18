//
//  EditorState.swift
//  Peek
//
//  Created by Til Blechschmidt on 07.03.21.
//

import UIKit
import Combine
import MarkdownKit

class EditorState {
    @Published var isEditingContent: Bool = false
    @Published var horizontalCharacterOffset: CGFloat = 0

    let focusEngine = FocusEngine()
    let blockManager: BlockManager

    init(blockManager: BlockManager) {
        self.blockManager = blockManager
        focusEngine.delegate = blockManager
    }
}
