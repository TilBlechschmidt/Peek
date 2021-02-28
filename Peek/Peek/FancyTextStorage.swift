//
//  FancyTextStorage.swift
//  Peek
//
//  Created by Til Blechschmidt on 19.02.21.
//

import UIKit
import MarkdownKit

class EmphasisCollector: InlineParserDelegate {
    private let input: Substring
    private(set) var emphasisSet: Set<Emphasis> = Set()

    init(_ input: Substring) {
        self.input = input

        var parser = InlineParser(Substring(input))
        parser.delegate = self
        parser.start()
    }

    func inlineParserDidEncounter(emphasis: Emphasis) {
        emphasisSet.insert(emphasis)
    }
}

class FancyTextStorage: NSTextStorage {
    let backingStore = NSMutableAttributedString()
    var cursorPosition: Int = 0

//    var currentEmphasis: Set<Emphasis> = Set()

    override var string: String {
        backingStore.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        backingStore.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
//        print("replaceCharactersInRange:\(range) withString:\(str)")

        // TODO In theory we have to shift all emphasis in currentEmphasis according to the change! Because after all, that is what happens.
        //      That would also allow this to work async. Maybe the "incremental" part should be handled by the Parser itself though for internal optimization.
        //      Then we could keep most of the stack, shift what has been shifted, delete/add what has been added and call it a day.
//        let newString = string.replacingCharacters(in: Range(range, in: string)!, with: str)
//        let newEmphasis = EmphasisCollector(Substring(newString)).emphasisSet
//        let addedEmphasis = newEmphasis.subtracting(currentEmphasis)
//        let removedEmphasis = currentEmphasis.subtracting(newEmphasis)
//        currentEmphasis = newEmphasis

        beginEditing()

        // Remove all old attributes
//        for removed in removedEmphasis {
//            let range = NSRange(removed.range, in: string)
//            backingStore.setAttributes([
//                .font: UIFont.systemFont(ofSize: 13),
//                .foregroundColor: UIColor.white
//            ], range: range)
//            edited(.editedAttributes, range: range, changeInLength: 0)
//        }

        // Commit the text change
        backingStore.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: (str as NSString).length - range.length)

        // Add all new attributes
//        for added in addedEmphasis {
//            let range = NSRange(added.range, in: string)
//            backingStore.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 13), range: range)
//            edited(.editedAttributes, range: range, changeInLength: 0)
//        }

        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
//        print("setAttributes:\(String(describing: attrs)) range:\(range)")

        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    func applyStyles() {
        backingStore.setAttributes([
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.label
        ], range: NSRange(location: 0, length: string.count))

        let string = backingStore.string
        var parser = InlineParser(Substring(string))
        parser.delegate = self
        parser.start()
    }
//    func applyStyles(for node: Node, baseStyles: FormattingOptions = .init()) {
//        if let formattable = node.variant as? Formattable {
//            // TODO This is really inefficient and ugly.
//            let cursorIsWithin = node.isPositionWithinNode(string.index(string.startIndex, offsetBy: cursorPosition))
//    || (cursorPosition > 0 ? node.isPositionWithinNode(string.index(string.startIndex, offsetBy: cursorPosition - 1)) : false)
//
//            for token in node.consumedTokens {
//                let format = formattable.formatting(for: token, cursorIsWithin: cursorIsWithin).union(baseStyles)
////                setAttributes(format.attributes(), range: NSRange(token.range, in: backingStore.string))
//                backingStore.setAttributes(format.attributes(), range: NSRange(token.range, in: backingStore.string))
//            }
//
//            let childStyles = formattable.formattingForChildren()
//            for child in node.children {
//                applyStyles(for: child, baseStyles: childStyles)
//            }
//        }
//    }

//    func applyStyles() {
//        let startTime = CFAbsoluteTimeGetCurrent()
//        let tokens = Lexer().tokenize(string: Substring(string))
//        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
//        print("Time elapsed for lexing:\t\t\(timeElapsed) s.")
//
//        let startTime2 = CFAbsoluteTimeGetCurrent()
//        guard let nodes = try? Parser(permittedVariants: .inlineVariants).parse(tokens) else {
//            return
//        }
//        let timeElapsed2 = CFAbsoluteTimeGetCurrent() - startTime2
//        print("Time elapsed for parsing:\t\t\(timeElapsed2) s.")
//
//        beginEditing()
//        printTimeElapsedWhenRunningCode(title: "node styling") {
//            for node in nodes {
//                self.applyStyles(for: node)
//            }
//        }
//        edited(.editedAttributes, range: NSRange(location: 0, length: string.count), changeInLength: 0)
//        endEditing()
//    }

    func applyStylesToRange(searchRange: NSRange) {
//        let range = Range<String.Index>(searchRange, in: backingStore.string)!
//        let substring = backingStore.string[range]
//
//        print("-----TOKENS-----")
//        for token in tokens {
//            print(token.variant)
//        }
//        print("---------------")
//
//        let nodes = try! InlineParser().parse(tokens)
//
//        print("-----NODES-----")
//        for node in nodes {
//            print(node)
//            if let convertible = node as? AttributeConvertible {
//                let attributes = convertible.attributes(in: backingStore.string)
//                for attribute in attributes {
//                    setAttributes(attribute.attributes, range: attribute.range)
//                }
//            }
//        }
//        print("---------------")
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

//    func performReplacementsForRange(changedRange: NSRange) {
//        var extendedRange = NSUnionRange(changedRange, NSString(string: backingStore.string).lineRange(for: NSMakeRange(changedRange.location, 0)))
//        extendedRange = NSUnionRange(changedRange, NSString(string: backingStore.string).lineRange(for: NSMakeRange(NSMaxRange(changedRange), 0)))
//        applyStylesToRange(searchRange: extendedRange)
//    }

    override func processEditing() {
        applyStyles()
//        performReplacementsForRange(changedRange: editedRange)
        super.processEditing()
    }
}

extension FancyTextStorage: InlineParserDelegate {
    func inlineParserDidEncounter(emphasis: Emphasis) {
        let emphasisRange = NSRange(emphasis.opener.lowerBound..<emphasis.closer.upperBound, in: string)
        let cursorInRange = emphasisRange.contains(cursorPosition) || emphasisRange.contains(cursorPosition - 1)
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 13)]
        let delimiterAttributes: [NSAttributedString.Key: Any] = cursorInRange ? [:] : [.font: UIFont.systemFont(ofSize: 0)]

//        addAttributes(attributes, range: NSRange(emphasis.content, in: string))
//        addAttributes(delimiterAttributes, range: NSRange(emphasis.opener, in: string))
//        addAttributes(delimiterAttributes, range: NSRange(emphasis.closer, in: string))
    }
}

extension FancyTextStorage: UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        cursorPosition = textView.selectedRange.location
        applyStyles()
//        let normalFont = UIFont.preferredFont(forTextStyle: .body)
//        let normalAttributes = [NSAttributedString.Key.font: normalFont]
//
//        textView.typingAttributes = normalAttributes
//
//        print("Default attributes: \(textView.typingAttributes)")
//        print("New selection: \(textView.selectedTextRange)")
    }
}


// TODO: Write extension to NSAttributableString which accepts Range<Substring.Index> or Range<String.Index>

func printTimeElapsedWhenRunningCode(title: String, operation: () -> ()) {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed for \(title): \(timeElapsed) s.")
}
