//
//  FormattingOptions.swift
//  
//
//  Created by Til Blechschmidt on 24.02.21.
//

import Foundation

public struct FormattingOptions: OptionSet {
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public let rawValue: Int

    // Generic
    public static let hidden           = FormattingOptions(rawValue: 1 << 0)

    // Emphasis
    public static let italics          = FormattingOptions(rawValue: 1 << 1)
    public static let bold             = FormattingOptions(rawValue: 1 << 2)
    public static let underline        = FormattingOptions(rawValue: 1 << 3)
    public static let highlighted      = FormattingOptions(rawValue: 1 << 4)
    public static let strikethrough    = FormattingOptions(rawValue: 1 << 5)
    public static let `subscript`      = FormattingOptions(rawValue: 1 << 6)
    public static let superscript      = FormattingOptions(rawValue: 1 << 7)

    // Code
    public static let monospaced       = FormattingOptions(rawValue: 1 << 8)
}

// MARK: - TODO Move this into its own file (FormattingOptions+NSAttributedString)

#if canImport(UIKit)
import UIKit

extension FormattingOptions {
    public func attributes() -> [NSAttributedString.Key : Any] {
        var fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        var attributes: [NSAttributedString.Key : Any] = [
            .foregroundColor: UIColor.white
        ]

        // TODO Handle error for font descriptors

        // Emphasis
        if contains(.italics) {
            fontDescriptor = fontDescriptor.withSymbolicTraits(.traitItalic)!
        }
        if contains(.bold) {
            fontDescriptor = fontDescriptor.withSymbolicTraits(.traitBold)!
        }
        if contains(.underline) {
            attributes[.underlineStyle] = NSNumber(value: NSUnderlineStyle.single.rawValue)
        }
        if contains(.highlighted) {
            attributes[.backgroundColor] = UIColor.systemYellow.withAlphaComponent(0.45)
        }
        if contains(.strikethrough) {
            attributes[.strikethroughStyle] = NSNumber(value: NSUnderlineStyle.single.rawValue)
        }
        if contains(.subscript) {
            attributes[.baselineOffset] = NSNumber(value: Double(-fontDescriptor.pointSize))
        }
        if contains(.superscript) {
            attributes[.baselineOffset] = NSNumber(value: Double(fontDescriptor.pointSize))
        }

        // Code
        if contains(.monospaced) {
            fontDescriptor = fontDescriptor.withSymbolicTraits(.traitMonoSpace)!
        }

        // Apply font styles
        attributes[.font] = UIFont(descriptor: fontDescriptor, size: 0.0)

        // Generic
        if contains(.hidden) {
            attributes[.font] = UIFont.systemFont(ofSize: 0)
        }

        return attributes
    }
}
#endif

// MARK: - TODO Move this stuff into own files

extension Node {
    public func isPositionWithinNode(_ position: Substring.Index) -> Bool {
        if consumedTokens.reduce(false, { $0 || $1.range.contains(position) }) {
            return true
        }

        for child in children {
            if child.isPositionWithinNode(position) {
                return true
            }
        }

        return false
    }
}

public protocol Formattable {
    func formatting(for consumedToken: Token, cursorIsWithin: Bool) -> FormattingOptions
    func formattingForChildren() -> FormattingOptions
}

extension NodeVariant {
    public func formatting(for consumedToken: Token, cursorIsWithin: Bool = false) -> FormattingOptions {
        FormattingOptions()
    }

    public func formattingForChildren() -> FormattingOptions {
        FormattingOptions()
    }
}

extension Text: Formattable {}
extension VerbatimText: Formattable {}

extension CodeSpan: Formattable {
    public func formatting(for consumedToken: Token, cursorIsWithin: Bool) -> FormattingOptions {
        cursorIsWithin ? .monospaced : .hidden
    }

    public func formattingForChildren() -> FormattingOptions {
        .monospaced
    }
}

extension Emphasis: Formattable {
    private var formatting: FormattingOptions {
        switch variant {
        case .italics:
            return .italics
        case .bold:
            return .bold
        case .underline:
            return .underline
        case .highlight:
            return .highlighted
        case .strikethrough:
            return .strikethrough
        case .subscript:
            return .subscript
        case .superscript:
            return .superscript
        }
    }

    public func formatting(for consumedToken: Token, cursorIsWithin: Bool) -> FormattingOptions {
        cursorIsWithin ? formatting : .hidden
    }

    public func formattingForChildren() -> FormattingOptions {
        formatting
    }
}
