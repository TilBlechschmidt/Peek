//
//  NodeVariant.swift
//  
//
//  Created by Til Blechschmidt on 21.02.21.
//

import Foundation

protocol NodeVariant: CustomDebugStringConvertible {
    func isEqual(to other: NodeVariant) -> Bool
}

// These are mostly a marker trait to distinguish inline content vs. blocks
//
// While the parser itself does not require this distinction,
// some consumers of the AST might fancy it :D
//
// And to be fair, we use it for the VariantRestriction 🤷‍♂️
protocol InlineNodeVariant: NodeVariant {}
protocol BlockNodeVariant: NodeVariant {}

// MARK: Custom equatable for NodeVariant and [NodeVariant]

extension NodeVariant where Self: Equatable {
    func isEqual(to other: NodeVariant) -> Bool {
        if let o = other as? Self {
            return o == self
        } else {
            return false
        }
    }
}

func == (a: [NodeVariant], b: [NodeVariant]) -> Bool {
    guard a.count == b.count else { return false }

    for i in 0..<a.count {
        if !(a[i].isEqual(to: b[i])) {
            return false
        }
    }

    return true
}
