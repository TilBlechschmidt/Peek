//
//  File.swift
//  
//
//  Created by Til Blechschmidt on 20.01.21.
//

import Foundation

public protocol Block {
    func isEqual(to other: Block) -> Bool
}

extension Block where Self: Equatable {
    func isEqual(to other: Block) -> Bool {
        if let o = other as? Self {
            return o == self
        } else {
            return false
        }
    }
}

func == (a: [Block], b: [Block]) -> Bool {
    guard a.count == b.count else { return false }

    for i in 0..<a.count {
        if !(a[i].isEqual(to: b[i])) {
            return false
        }
    }

    return true
}

protocol ReadableBlock: Block, Readable {}
