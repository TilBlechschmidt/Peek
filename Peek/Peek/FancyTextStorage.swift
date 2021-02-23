//
//  FancyTextStorage.swift
//  Peek
//
//  Created by Til Blechschmidt on 19.02.21.
//

import UIKit
import MarkdownKit

class FancyTextStorage: NSTextStorage {
    let backingStore = NSMutableAttributedString()

    override var string: String {
        backingStore.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        backingStore.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        print("replaceCharactersInRange:\(range) withString:\(str)")

        beginEditing()
        backingStore.replaceCharacters(in: range, with:str)
        edited(.editedCharacters, range: range, changeInLength: (str as NSString).length - range.length)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        print("setAttributes:\(String(describing: attrs)) range:\(range)")

        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    func applyStylesToRange(searchRange: NSRange) {
        let range = Range<String.Index>(searchRange, in: backingStore.string)!
        let substring = backingStore.string[range]

        let tokens = Lexer().tokenize(string: substring)

        print("-----TOKENS-----")
        for token in tokens {
            print(token.variant)
        }
        print("---------------")

        let nodes = try! InlineParser().parse(tokens)

        print("-----NODES-----")
        for node in nodes {
            print(node)
            if let convertible = node as? AttributeConvertible {
                let attributes = convertible.attributes(in: backingStore.string)
                for attribute in attributes {
                    setAttributes(attribute.attributes, range: attribute.range)
                }
            }
        }
        print("---------------")
//        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
//        let boldFontDescriptor = fontDescriptor.withSymbolicTraits(.traitBold)
//        let boldFont = UIFont(descriptor: boldFontDescriptor!, size: 0)
//        let normalFont = UIFont.preferredFont(forTextStyle: .body)
//
//        let regexStr = "(\\*\\w+(\\s\\w+)*\\*)"
//        let regex = try! NSRegularExpression(pattern: regexStr)
//        let boldAttributes = [NSAttributedString.Key.font: boldFont]
//        let normalAttributes = [NSAttributedString.Key.font: normalFont]
//
//        regex.enumerateMatches(in: backingStore.string, range: searchRange) { match, flags, stop in
//            if let matchRange = match?.range(at: 1) {
//                addAttributes(boldAttributes, range: matchRange)
//
//                let hiddenAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 0)]
//                setAttributes(hiddenAttributes, range: NSRange(location: matchRange.lowerBound, length: 1))
//                setAttributes(hiddenAttributes, range: NSRange(location: matchRange.upperBound - 1, length: 1))
//
//                let maxRange = matchRange.location + matchRange.length
//                if maxRange + 1 < length {
//                    addAttributes(normalAttributes, range: NSMakeRange(maxRange, 1))
//                }
//            }
//        }
    }

    func performReplacementsForRange(changedRange: NSRange) {
        var extendedRange = NSUnionRange(changedRange, NSString(string: backingStore.string).lineRange(for: NSMakeRange(changedRange.location, 0)))
        extendedRange = NSUnionRange(changedRange, NSString(string: backingStore.string).lineRange(for: NSMakeRange(NSMaxRange(changedRange), 0)))
        applyStylesToRange(searchRange: extendedRange)
    }

    override func processEditing() {
        print("---PROCESS EDITING")
        performReplacementsForRange(changedRange: editedRange)
        super.processEditing()
    }
}

extension FancyTextStorage: UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
//        let normalFont = UIFont.preferredFont(forTextStyle: .body)
//        let normalAttributes = [NSAttributedString.Key.font: normalFont]
//
//        textView.typingAttributes = normalAttributes

//        print("Default attributes: \(textView.typingAttributes)")
//        print("New selection: \(textView.selectedTextRange)")
    }
}


// TODO: Write extension to NSAttributableString which accepts Range<Substring.Index> or Range<String.Index>
