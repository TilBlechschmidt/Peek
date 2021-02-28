import XCTest
@testable import MarkdownKit

final class MarkdownKitTests: XCTestCase {
    // MARK: - Basic line parsing

    func testIndentationWithNewline() {
        let input: Substring = "   \n"
        let line = Line(from: input, matchers: [])

        XCTAssertEqual(line.stack, [
            .indentation(3),
        ])
        XCTAssert(line.isEmpty)
    }

    func testIndentationForEmptyLine() {
        let input: Substring = "    "
        let line = Line(from: input, matchers: [])

        XCTAssertEqual(line.stack, [
            .indentation(4)
        ])
        XCTAssert(line.isEmpty)
    }

    func testNoIndentation() {
        let input: Substring = "Test"
        let line = Line(from: input, matchers: [])

        XCTAssertEqual(line.stack, [
            .text(input.startIndex..<input.endIndex)
        ])
    }

    func testEmptyLine() {
        let input: Substring = ""
        let line = Line(from: input, matchers: [])

        XCTAssertEqual(line.stack, [])
        XCTAssert(line.isEmpty)
    }

    func testTextLineIsText() {
        let input: Substring = "Test"
        let line = Line(from: input, matchers: [])

        XCTAssert(line.isText)
    }

    func testIndentedTextLineIsText() {
        let input: Substring = "  Test"
        let line = Line(from: input, matchers: [])

        XCTAssert(line.isText)
    }

    func testIndentedLineIsText() {
        let input: Substring = "    "
        let line = Line(from: input, matchers: [])

        XCTAssert(line.isText)
    }

    func testEmptyLineIsText() {
        let input: Substring = "    "
        let line = Line(from: input, matchers: [])

        XCTAssert(line.isText)
    }

    // MARK: - Node matching

    // MARK: Paragraph

    func testParagraphLine() {
        let input: Substring = "Hello"
        let line = Line(from: input, matchers: [Paragraph.Matcher()])

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(Paragraph()),
            .text(input.startIndex..<input.endIndex)
        ])
    }

    func testIndentedParagraphLine() {
        let input: Substring = "   Hello"
        let line = Line(from: input, matchers: [Paragraph.Matcher()])
        let textRange = input.index(input.startIndex, offsetBy: 3)..<input.endIndex

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .indentation(3),
            .block(Paragraph()),
            .text(textRange)
        ])
    }

    func testParagraphNotMatchingEmptyLine() {
        let input: Substring = "  "
        let line = Line(from: input, matchers: [Paragraph.Matcher()])

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .indentation(2)
        ])
    }

    // MARK: Container

    func testBlockquoteLine() {
        let input: Substring = ">Hello"
        let line = Line(from: input, matchers: [Container.Matcher(variant: .blockquote)])
        let textRange = input.index(after: input.startIndex)..<input.endIndex

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(Container(variant: .blockquote)),
            .text(textRange)
        ])
    }

    func testBlockquoteLineWithWhitespace() {
        let input: Substring = "> Hello"
        let line = Line(from: input, matchers: [Container.Matcher(variant: .blockquote)])
        let textRange = input.index(input.startIndex, offsetBy: 2)..<input.endIndex

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(Container(variant: .blockquote)),
            .text(textRange)
        ])
    }

    func testBlockquoteNestingIsDisallowed() {
        let input: Substring = "> > Hello"
        let line = Line(from: input, matchers: [Container.Matcher(variant: .blockquote)])
        let textRange = input.index(input.startIndex, offsetBy: 2)..<input.endIndex

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(Container(variant: .blockquote)),
            .text(textRange)
        ])
    }

    func testBlockquoteAdmonitionNesting() {
        let input: Substring = "> | Hello"
        let line = Line(from: input, matchers: [Container.Matcher(variant: .blockquote), Container.Matcher(variant: .admonition)])
        let textRange = input.index(input.startIndex, offsetBy: 4)..<input.endIndex

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(Container(variant: .blockquote)),
            .block(Container(variant: .admonition)),
            .text(textRange)
        ])
    }

    func testBlockquoteAdmonitionBlockquoteNestingIsDisallowed() {
        let input: Substring = "> | > Hello"
        let line = Line(from: input, matchers: [Container.Matcher(variant: .blockquote), Container.Matcher(variant: .admonition)])
        let textRange = input.index(input.startIndex, offsetBy: 4)..<input.endIndex

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(Container(variant: .blockquote)),
            .block(Container(variant: .admonition)),
            .text(textRange)
        ])
    }

    func testAdmonitionContainerVariant() {
        let input: Substring = "|Hello"
        let line = Line(from: input, matchers: [Container.Matcher(variant: .admonition)])
        let textRange = input.index(after: input.startIndex)..<input.endIndex

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(Container(variant: .admonition)),
            .text(textRange)
        ])
    }

    // MARK: Thematic break

    func testThematicBreakLine() {
        let input: Substring = "***"
        let line = Line(from: input, matchers: [ThematicBreak.Matcher()])

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(ThematicBreak(variant: .dots)),
        ])
    }

    func testThematicBreakLineWithWhitespaces() {
        let input: Substring = "* * *"
        let line = Line(from: input, matchers: [ThematicBreak.Matcher()])

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(ThematicBreak(variant: .dots)),
        ])
    }

    func testThematicBreakLineWithTooFewMarkers() {
        let input: Substring = "**"
        let line = Line(from: input, matchers: [ThematicBreak.Matcher()])

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .text(input.startIndex..<input.endIndex),
        ])
    }

    func testThematicBreakLineWithManyMarkers() {
        let input: Substring = "*********"
        let line = Line(from: input, matchers: [ThematicBreak.Matcher()])

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(ThematicBreak(variant: .dots)),
        ])
    }

    func testThematicBreakLineVariant() {
        let input: Substring = "---"
        let line = Line(from: input, matchers: [ThematicBreak.Matcher()])

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(ThematicBreak(variant: .line)),
        ])
    }

    func testThematicBreakThickLineVariant() {
        let input: Substring = "___"
        let line = Line(from: input, matchers: [ThematicBreak.Matcher()])

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(ThematicBreak(variant: .thickLine)),
        ])
    }

    // MARK: Heading

    func testHeadingLine() {
        let input: Substring = "# Hello"
        let line = Line(from: input, matchers: [Heading.Matcher()])
        let textRange = input.index(input.startIndex, offsetBy: 2)..<input.endIndex

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(Heading(level: 1)),
            .text(textRange)
        ])
    }

    func testHeadingLineWithoutText() {
        let input: Substring = "#"
        let line = Line(from: input, matchers: [Heading.Matcher()])

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(Heading(level: 1)),
        ])
    }

    func testHeadingLineWithoutWhitespace() {
        let input: Substring = "#Test"
        let line = Line(from: input, matchers: [Heading.Matcher()])

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .text(input.startIndex..<input.endIndex)
        ])
    }

    func testHeadingLineWithoutTextAndFollowingLine() {
        let input: Substring = "#\nTest"
        let line = Line(from: input, matchers: [Heading.Matcher()])

        XCTAssertEqual(line.upperBound, input.index(input.startIndex, offsetBy: 2))
        XCTAssertEqual(line.stack, [
            .block(Heading(level: 1))
        ])
    }

    // MARK: Code block

    func testUnclosedCodeBlockWithoutContentOrLanguage() {
        let input: Substring = "```"
        let line = Line(from: input, matchers: [CodeBlock.Matcher()])

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(CodeBlock(language: input.endIndex..<input.endIndex, content: input.endIndex..<input.endIndex))
        ])
    }

    func testUnclosedCodeBlockWithoutContent() {
        let input: Substring = "```swift"
        let line = Line(from: input, matchers: [CodeBlock.Matcher()])

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(CodeBlock(language: input.range(of: "swift")!, content: input.endIndex..<input.endIndex))
        ])
    }

    func testUnclosedCodeBlockWithoutLanguage() {
        let input: Substring = "```\nHello"
        let line = Line(from: input, matchers: [CodeBlock.Matcher()])
        let language = input.firstIndex(of: "\n")!..<input.firstIndex(of: "\n")!

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(CodeBlock(language: language, content: input.range(of: "Hello")!))
        ])
    }

    func testUnclosedCodeBlock() {
        let input: Substring = "```swift\nHello"
        let line = Line(from: input, matchers: [CodeBlock.Matcher()])

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(CodeBlock(language: input.range(of: "swift")!, content: input.range(of: "Hello")!))
        ])
    }

    func testClosedCodeBlockWithoutLanguageOrContent() {
        let input: Substring = "```\n```"
        let line = Line(from: input, matchers: [CodeBlock.Matcher()])
        let language = input.firstIndex(of: "\n")!..<input.firstIndex(of: "\n")!
        let content = input.index(after: language.upperBound)..<input.index(after: language.upperBound)

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(CodeBlock(language: language, content: content))
        ])
    }

    func testClosedCodeBlockWithoutLanguageOrContentAndTrailingWhitespace() {
        let input: Substring = "```\n```  "
        let line = Line(from: input, matchers: [CodeBlock.Matcher()])
        let language = input.firstIndex(of: "\n")!..<input.firstIndex(of: "\n")!
        let content = input.index(after: language.upperBound)..<input.index(after: language.upperBound)

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(CodeBlock(language: language, content: content))
        ])
    }

    func testClosedCodeBlockWithoutLanguage() {
        let input: Substring = "```\nHello```"
        let line = Line(from: input, matchers: [CodeBlock.Matcher()])
        let language = input.firstIndex(of: "\n")!..<input.firstIndex(of: "\n")!
        let content = input.range(of: "Hello")!

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(CodeBlock(language: language, content: content))
        ])
    }

    func testClosedCodeBlockWithoutLanguageAndNewline() {
        let input: Substring = "```\nHello\n```"
        let line = Line(from: input, matchers: [CodeBlock.Matcher()])
        let language = input.firstIndex(of: "\n")!..<input.firstIndex(of: "\n")!
        let content = input.range(of: "Hello\n")!

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(CodeBlock(language: language, content: content))
        ])
    }

    func testClosedCodeBlockWithoutLanguageAndTrailingContent() {
        let input: Substring = "```\nHello```\nTest"
        let line = Line(from: input, matchers: [CodeBlock.Matcher()])
        let language = input.firstIndex(of: "\n")!..<input.firstIndex(of: "\n")!
        let content = input.index(input.startIndex, offsetBy: 4)..<input.index(input.startIndex, offsetBy: 9)

        // Due to weirdness with String Index comparisons we have to compare them ourselves.
        // I suspect that indices built on substrings of substrings are internally different
        // even when referencing the same range and thus do not compare as equal.
        if case .block(let code) = line.stack.first!, let c = code as? CodeBlock {
            XCTAssertEqual(language, c.language)
            XCTAssertEqual(content, c.content)
        }

        XCTAssertEqual(line.upperBound, input.firstIndex(of: "T")!)
    }

    func testClosedCodeBlock() {
        let input: Substring = "```swift\nHello```"
        let line = Line(from: input, matchers: [CodeBlock.Matcher()])
        let language = input.range(of: "swift")!
        let content = input.range(of: "Hello")!

        XCTAssertEqual(line.upperBound, input.endIndex)
        XCTAssertEqual(line.stack, [
            .block(CodeBlock(language: language, content: content))
        ])
    }

    // MARK: - Line mutation

    func testIgnoreIndentation() {
        var line = Line(from: "   ", matchers: [])
        XCTAssertEqual(line.stack, [.indentation(3)])
        line.ignoreIndentation()
        XCTAssert(line.stack.isEmpty)
    }

    func testPopStackBottom() {
        let input: Substring = "Hello"
        var line = Line(from: input, matchers: [])
        let expectedText = LineContent.text(input.startIndex..<input.endIndex)

        XCTAssertEqual(line.stack, [expectedText])
        let text = line.popStackBottom()
        XCTAssertEqual(text, expectedText)
        XCTAssert(line.stack.isEmpty)
    }

    func testIgnoringIndentationOnIndentedTextLineDoesNotSpin() {
        let input: Substring = "  Miep"
        var line = Line(from: input, matchers: [])
        line.ignoreIndentation()
    }

    // MARK: - Node continuation

    // MARK: Paragraph

    func testParagraphContinuation() {
        let input: Substring = "  Miep"
        let line = Line(from: input, matchers: [Paragraph.Matcher()])

        let continuationLine = Paragraph().continue(on: line)!
        XCTAssertEqual(continuationLine.stack, [
            .text(input.index(input.startIndex, offsetBy: 2)..<input.endIndex)
        ])
    }

    func testParagraphTerminatingOnBlockquote() {
        let input: Substring = "  > Miep"
        let line = Line(from: input, matchers: [Container.Matcher(variant: .blockquote), Paragraph.Matcher()])

        let continuationLine = Paragraph().continue(on: line)
        XCTAssert(continuationLine == nil)
    }

    func testParagraphTerminatingOnEmptyLine() {
        let input: Substring = ""
        let line = Line(from: input, matchers: [Paragraph.Matcher()])

        let continuationLine = Paragraph().continue(on: line)
        XCTAssert(continuationLine == nil)
    }

    // MARK: Container

    func testBlockquoteContinuation() {
        let input: Substring = "  > Miep"
        let line = Line(from: input, matchers: [Container.Matcher(variant: .blockquote)])

        let continuationLine = Container(variant: .blockquote).continue(on: line)!
        XCTAssertEqual(continuationLine.stack, [
            .text(input.index(input.startIndex, offsetBy: 4)..<input.endIndex)
        ])
    }

    func testBlockquoteAllowsLazyParagraphContinuation() {
        let input: Substring = "Hello"
        let line = Line(from: input, matchers: [Container.Matcher(variant: .blockquote), Paragraph.Matcher()])

        let continuationLine = Container(variant: .blockquote).continue(on: line)!
        XCTAssertEqual(continuationLine.stack, [
            .block(Paragraph()),
            .text(input.startIndex..<input.endIndex)
        ])
    }

    func testBlockquoteAllowsLazyIndentedParagraphContinuation() {
        let input: Substring = "  Hello"
        let line = Line(from: input, matchers: [Container.Matcher(variant: .blockquote), Paragraph.Matcher()])

        let continuationLine = Container(variant: .blockquote).continue(on: line)!
        XCTAssertEqual(continuationLine.stack, [
            .indentation(2),
            .block(Paragraph()),
            .text(input.index(input.startIndex, offsetBy: 2)..<input.endIndex)
        ])
    }

    func testBlockquoteTerminatingOnEmptyLine() {
        let input: Substring = ""
        let line = Line(from: input, matchers: [Container.Matcher(variant: .blockquote)])

        XCTAssert(Container(variant: .blockquote).continue(on: line) == nil)
    }

    // MARK: Thematic break

    func testThematicBreakDisallowsContinuation() {
        XCTAssert(ThematicBreak(variant: .dots).continue(on: Line(from: "", matchers: [])) == nil)
    }

    // MARK: Heading

    func testHeadingDisallowsContinuation() {
        XCTAssert(Heading(level: 1).continue(on: Line(from: "", matchers: [])) == nil)
    }

    // MARK: - BlockParser

    func testBlockParser() {
        // TODO Should generate one Paragraph with one "Test" inline content.
        //      Instead it creates one big Paragraph with a bunch of newlines :(
        // TODO Write a test case for this!
        let input: Substring = "\n\n\nTest\n\n\n\n\n"
        var parser = NodeParser(input)

        class Delegate: NodeParserDelegate {
            let input: Substring

            init(_ input: Substring) {
                self.input = input
            }

            func blockParserDidEnter(block: Node) {
                print("OPEN  \(block)")
            }

            func blockParserDidExit(block: Node) {
                print("EXIT  \(block)")
            }

            func blockParserDidReadInlineContent(in range: Range<Substring.Index>) {
                print("TEXT  \(String(reflecting: input[range]))")
            }
        }

        let delegate = Delegate(input)

        parser.delegate = delegate
        parser.start()
    }

    // MARK: - Inline parser

    // MARK: Delimiter run

    func testDelimiterRunRangeAndCount() {
        let input: Substring = "*** def"
        let delimiterRun = DelimiterRun("*", from: input, previousCharacter: " ")
        XCTAssertEqual(delimiterRun.range, input.range(of: "***"))
        XCTAssertEqual(delimiterRun.count, 3)
    }

    func testLeftFlankingDelimiterRun() {
        let runs: [(Substring, Character?)] = [
            ("***abc", nil),
            ("*abc", " "),
            ("**\"abc\"", nil),
            ("*\"abc\"", " ")
        ]

        for (text, previousCharacter) in runs {
            let delimiterRun = DelimiterRun("*", from: text, previousCharacter: previousCharacter)
            XCTAssertEqual(delimiterRun.flanking, [.left])
        }
    }

    func testRightFlankingDelimiterRun() {
        let runs: [(Substring, Character?)] = [
            ("***", "c"),
            ("**", "\""),
        ]

        for (text, previousCharacter) in runs {
            let delimiterRun = DelimiterRun("*", from: text, previousCharacter: previousCharacter)
            XCTAssertEqual(delimiterRun.flanking, [.right])
        }
    }

    func testBothFlankingDelimiterRun() {
        let runs: [(Substring, Character?)] = [
            ("***def", "c"),
            ("*\"def\"", "\""),
        ]

        for (text, previousCharacter) in runs {
            let delimiterRun = DelimiterRun("*", from: text, previousCharacter: previousCharacter)
            XCTAssertEqual(delimiterRun.flanking, [.left, .right])
        }
    }

    func testNonFlankingDelimiterRun() {
        let delimiterRun = DelimiterRun("*", from: "*** def", previousCharacter: " ")
        XCTAssertEqual(delimiterRun.flanking, [])
    }

    func testInlineParser() {
        let input: Substring = "==This== *is *a test** __test__ ***blub** bla*"
//        let input: Substring = Substring(String(repeating: "Hello *world*! Now the *big* **question** here _is_ just =why= it is so *incredibly *slow**! Hello *world*! Now the *big* **question** here _is_ just =why= it is so *incredibly *slow**! Hello *world*! Now the *big* **question** here _is_ just =why= it is so *incredibly *slow**! Hello *world*! Now the *big* **question** here _is_ just =why= it is so *incredibly *slow**! Hello *world*! Now the *big* **question** here _is_ just =why= it is so *incredibly *slow**! Hello *world*! Now the *big* **question** here _is_ just =why= it is so *incredibly *slow**! Hello *world*!", count: 100))
        let parser = InlineParser(input)
        parser.start()
    }

    // MARK: - Block aggregator

    func testBlockAggregator() {
        let input: Substring = """
        #
        > Test
        Bla
        ```swift
        func main() {
            print("Hello world!")
        }
        ```
        | > Blub
        """

        let aggregator = BlockAggregator(input)
        var parser = NodeParser(input)
        parser.delegate = aggregator
        parser.start()

        for block in aggregator.blocks {
            switch block.content {
            case .thematicBreak(let variant):
                print("ThematicBreak(variant: \(variant)")
            case .heading(let level, let content):
                print("Heading(level: \(level)) => \(content.map { String(reflecting: $0) } ?? "<no content>")")
            case .code(let language, let content):
                print("CodeBlock(language: \(String(reflecting: language))) => \(String(reflecting: content)))")
            case .text(let content):
                print("Text => \(String(reflecting: content))")
            }
        }
    }

//    static var allTests = [
//        ("testExample", testExample),
//    ]
}
