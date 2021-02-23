//
//  Node.swift
//  
//
//  Created by Til Blechschmidt on 21.02.21.
//

import Foundation

struct Node: CustomDebugStringConvertible {
    var debugDescription: String {
        let childStrings = children.map { $0.debugDescription.replacingOccurrences(of: "\n", with: "\n\t") }.joined(separator: "\n\t")
        return "\(variant.debugDescription)\(childStrings.isEmpty ? "" : " {\n\t\(childStrings)\n}")"
    }

    let tokens: ArraySlice<Token>
    let variant: NodeVariant
    let children: [Node]
}
