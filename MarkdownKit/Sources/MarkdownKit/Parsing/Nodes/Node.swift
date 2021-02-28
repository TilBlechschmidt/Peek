//
//  Node.swift
//  
//
//  Created by Til Blechschmidt on 26.02.21.
//

import Foundation

public protocol Node {
    func allows(childMatcher: NodeMatcher) -> Bool
    func `continue`(on line: Line) -> Line?

    func isEqual(to other: Node) -> Bool
}

extension Node where Self: Equatable {
    public func isEqual(to other: Node) -> Bool {
        if let other = other as? Self {
            return other == self
        } else {
            return false
        }
    }
}

public func == (lhs: [Node], rhs: [Node]) -> Bool {
    guard lhs.count == rhs.count else { return false }

    for index in 0..<lhs.count {
        if !(lhs[index].isEqual(to: rhs[index])) {
            return false
        }
    }

    return true
}
