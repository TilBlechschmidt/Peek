//
//  BlockManager.swift
//  Peek
//
//  Created by Til Blechschmidt on 13.04.21.
//

import Foundation
import Combine
import UIKit

class BlockManager {
    let instance = UUID()
    let blocks: CurrentValueSubject<[ContentBlock], Never> = CurrentValueSubject([])

    init(_ blocks: [ContentBlock] = []) {
        blocks.forEach {
            append($0)
        }
    }

    internal func index(of id: UUID) -> Int? {
        blocks.value.firstIndex(where: { $0.id == id })
    }

    internal func manages(_ id: UUID) -> Bool {
        index(of: id) != nil
    }
}
