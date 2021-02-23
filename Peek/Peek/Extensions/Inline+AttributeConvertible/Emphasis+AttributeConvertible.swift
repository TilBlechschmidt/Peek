//
//  Emphasis+Attributes.swift
//  Peek
//
//  Created by Til Blechschmidt on 20.02.21.
//

import UIKit
import MarkdownKit

extension Bold: AttributeConvertible {
    func attributes(in string: String) -> [RangedAttribute] {
        guard let firstContent = content.first, let lastContent = content.last else {
            return []
        }

        let openingRange = NSRange(openingDelimiter.range, in: string)
        let closingRange = NSRange(closingDelimiter.range, in: string)
        let contentRange = NSRange(firstContent.range.lowerBound..<lastContent.range.upperBound, in: string) // TODO Assume that the content tokens are unordered!

        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let boldFontDescriptor = fontDescriptor.withSymbolicTraits(.traitBold)
        let boldFont = UIFont(descriptor: boldFontDescriptor!, size: 0)
        let contentAttributes = [
            NSAttributedString.Key.font: boldFont,
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]

        let delimiterAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 0)]

        return [
            RangedAttribute(range: openingRange, attributes: delimiterAttributes),
            RangedAttribute(range: closingRange, attributes: delimiterAttributes),
            RangedAttribute(range: contentRange, attributes: contentAttributes)
        ]
    }
}

extension TextNode: AttributeConvertible {
    func attributes(in string: String) -> [RangedAttribute] {
        let contentAttributes = [
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]

        return [
            RangedAttribute(range: NSRange(token.range, in: string), attributes: contentAttributes)
        ]
    }
}
