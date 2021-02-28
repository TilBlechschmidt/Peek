//
//  BlockMatcher.swift
//  
//
//  Created by Til Blechschmidt on 26.02.21.
//

import Foundation

public protocol NodeMatcher {
    typealias NodeMatch = (Node, upperBound: Substring.Index)

    func match(substring: Substring) -> NodeMatch?
}
