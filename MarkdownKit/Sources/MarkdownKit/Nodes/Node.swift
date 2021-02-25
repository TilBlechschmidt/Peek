//
//  Node.swift
//  
//
//  Created by Til Blechschmidt on 21.02.21.
//

import Foundation

public struct Node: CustomDebugStringConvertible {
    public var debugDescription: String {
        let childStrings = children.map { $0.debugDescription.replacingOccurrences(of: "\n", with: "\n\t") }.joined(separator: "\n\t")
        return "\(variant.debugDescription)\(childStrings.isEmpty ? "" : " {\n\t\(childStrings)\n}")"
    }

    /// Tokens that have been consumed by the variants parser.
    /// Does not include Tokens which are parsed by children!
    public let consumedTokens: [Token]
    public let variant: NodeVariant
    public let children: [Node]
}
