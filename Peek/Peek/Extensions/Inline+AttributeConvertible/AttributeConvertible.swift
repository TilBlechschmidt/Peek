//
//  AttributeConvertible.swift
//  Peek
//
//  Created by Til Blechschmidt on 20.02.21.
//

import Foundation

struct RangedAttribute {
    let range: NSRange
    let attributes: [NSAttributedString.Key: Any]
}

protocol AttributeConvertible {
    func attributes(in string: String) -> [RangedAttribute]
}
