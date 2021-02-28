//
//  LineContent.swift
//  
//
//  Created by Til Blechschmidt on 26.02.21.
//

import Foundation

public enum LineContent: Equatable {
    case indentation(Int)
    case block(Node)
    case text(Range<Substring.Index>)

    public static func == (lhs: LineContent, rhs: LineContent) -> Bool {
        switch lhs {
        case .indentation(let count):
            if case .indentation(let otherCount) = rhs, count == otherCount { return true } else { return false }
        case .text(let range):
            if case .text(let otherRange) = rhs, range == otherRange { return true } else { return false }
        case .block(let block):
            if case .block(let otherBlock) = rhs, block.isEqual(to: otherBlock) { return true } else { return false }
        }
    }
}
