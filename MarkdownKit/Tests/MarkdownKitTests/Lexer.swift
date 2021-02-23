//
//  Lexer.swift
//
//
//  Created by Til Blechschmidt on 21.01.21.
//

import XCTest
@testable import MarkdownKit

final class LexerTests: XCTestCase {
    func testTokenization() {
        let input = Substring(#"hello `wonderful"#)
        let result = Lexer().tokenize(string: input)

        let helloRange = input.startIndex..<input.index(input.startIndex, offsetBy: 5)
        let whitespaceRange = input.index(input.startIndex, offsetBy: 5)..<input.index(input.startIndex, offsetBy: 6)
        let backtickRange = input.index(input.startIndex, offsetBy: 6)..<input.index(input.startIndex, offsetBy: 7)
        let wonderfulRange = input.index(input.startIndex, offsetBy: 7)..<input.index(input.startIndex, offsetBy: 16)

        let expected = [
            Token(.text("hello"), range: helloRange),
            Token(.whitespace, range: whitespaceRange),
            Token(.backtick, range: backtickRange),
            Token(.text("wonderful"), range: wonderfulRange)
        ]

        XCTAssertEqual(result, expected)
    }

    func testCodeSpan() throws {
        let input = Substring("```  Test  ````")
        let tokens = Lexer().tokenize(string: input)

        var reader = TokenReader(tokens: tokens)
        let (node, children) = try MarkdownKit.CodeSpan.Parser().read(using: &reader)

        XCTAssertEqual(node, MarkdownKit.CodeSpan())
        XCTAssertEqual(children.map({ input[$0.range] }).joined(), " Test ")
        XCTAssertEqual(try? reader.advance().variant, Token.Variant.backtick)
        XCTAssert(reader.didReachEnd)
    }

    func testVerbatimText() throws {
        let input = Substring("\\e")
        let tokens = Lexer().tokenize(string: input)

        var reader = TokenReader(tokens: tokens)
        let (node, children) = try MarkdownKit.VerbatimText.Parser().read(using: &reader)

        XCTAssertEqual(node, MarkdownKit.VerbatimText(content: .text("\\e")))
        XCTAssert(reader.didReachEnd)
        XCTAssert(children.isEmpty)
    }

    func testNewParser() throws {
//        let input: Substring = "- Hello\n  - World\n    - Bla\n- Test"
        let input: Substring = "1) Test\n2) Bla"
        let tokens = Lexer().tokenize(string: input)

        for token in tokens {
            print(token)
        }

        let nodes = try Parser().parse(tokens)

        print("\n")
        for node in nodes {
            debugPrint(node)
        }
        print("\n")
    }

    func testOrderedList() throws {
        try XCTVerifyAST(input: "1) Test\n2) Bla") {
            List(variant: .ordered) {
                ListItem(variant: .ordered) {
                    Paragraph {
                        Text.from("Test")
                    }
                }
                ListItem(variant: .ordered) {
                    Paragraph {
                        Text.from("Bla")
                    }
                }
            }
        }
    }

    func testOrderedListWithBlankLines() throws {
        try XCTVerifyAST(input: "1) Test\n\n\n\n\n2) Bla") {
            List(variant: .ordered) {
                ListItem(variant: .ordered) {
                    Paragraph {
                        Text.from("Test")
                    }
                }
                ListItem(variant: .ordered) {
                    Paragraph {
                        Text.from("Bla")
                    }
                }
            }
        }
    }

    func testOrderedListWithTrailingContent() throws {
        try XCTVerifyAST(input: "1) Test\n\n\n\n\nBla") {
            List(variant: .ordered) {
                ListItem(variant: .ordered) {
                    Paragraph {
                        Text.from("Test")
                    }
                }
            }
            Paragraph {
                Text.from("Bla")
            }
        }
    }

    func testBlockquotes() throws {
        try XCTVerifyAST(input: "> Hello\n>World\n\n> Test\n\n| Bla\n| Test") {
            Container(variant: .blockquote) {
                Paragraph {
                    Text.from("Hello")
                }
            }
            Paragraph {
                Text.from(">World")
            }
            Container(variant: .blockquote) {
                Paragraph {
                    Text.from("Test")
                }
            }
            Container(variant: .admonition) {
                Paragraph {
                    Text.from("Bla\nTest")
                }
            }
        }
    }

    func testBlockquotes2() throws {
        try XCTVerifyAST(input: "> Hello\n> World\n\n> Test\n\n>Test") {
            Container(variant: .blockquote) {
                Paragraph {
                    Text.from("Hello\nWorld")
                }
            }
            Container(variant: .blockquote) {
                Paragraph {
                    Text.from("Test")
                }
            }
            Paragraph {
                Text.from(">Test")
            }
        }
    }

    func testInlineVariantRestriction() {
        struct NonInlineVariant: NodeVariant {
            func isEqual(to other: NodeVariant) -> Bool {
                fatalError()
            }

            var debugDescription: String {
                ""
            }
        }

        XCTAssertTrue(VariantRestriction.inlineVariants.allows(variant: MarkdownKit.CodeSpan()))
        XCTAssertFalse(VariantRestriction.inlineVariants.allows(variant: NonInlineVariant()))
    }

    func testBlankLine() {
        let input: Substring = "aaa\n\nbbb"
        let tokens = Lexer().tokenize(string: input)

        XCTAssertEqual(tokens.count, 4)
        XCTAssertEqual(tokens[0].variant, .text("aaa"))
        XCTAssertEqual(tokens[1].variant, .lineFeed)
        XCTAssertEqual(tokens[2].variant, .lineFeed)
        XCTAssertEqual(tokens[3].variant, .text("bbb"))
    }

    func testParagraphParsing() throws {
        try XCTVerifyAST(input: "aaa\n  \nbbb") {
            Paragraph {
                Text.from("aaa")
            }
            Paragraph {
                Text.from("bbb")
            }
        }
    }

    func testHeadingParsing() throws {
        try XCTVerifyAST(input: "# Hello world\n\n") {
            Heading(level: 1) {
                Paragraph {
                    Text.from("Hello world")
                }
            }
        }
    }

    func testSingleLineParagraphParsing() throws {
        try XCTVerifyAST(input: "Hello world") {
            Paragraph {
                Text.from("Hello world")
            }
        }
    }

    func testBlankLines() throws {
        try XCTVerifyAST(input: "aaa\n\n\nbbb") {
            Paragraph {
                Text.from("aaa")
            }
            Paragraph {
                Text.from("bbb")
            }
        }
    }

    func testParagraphSerialization() throws {
        let rootNode = Paragraph {
            Text.from("Hello world!")
        }.makeNode()

        let serialized = try rootNode.markdownRepresentation()

        XCTAssertEqual("Hello world!\n\n", serialized)
    }

    func testEmphasisSerialization() throws {
        let rootNode = Paragraph {
            Text.from("Hello ")
            Emphasis(variant: .bold) {
                Text.from("world")
            }
            Text.from("!")
        }.makeNode()

        let serialized = try rootNode.markdownRepresentation()

        XCTAssertEqual("Hello *world*!\n\n", serialized)
    }

    func testCodeSpanSerialization() throws {
        let rootNode = CodeSpan {
            VerbatimText.from("Hello world")
        }.makeNode()

        let serialized = try rootNode.markdownRepresentation()

        XCTAssertEqual("`Hello world`", serialized)
    }

    func testCodeSpanSerializationWithBackticks() throws {
        let rootNode = CodeSpan {
            VerbatimText.from("Hello ``` world")
        }.makeNode()

        let serialized = try rootNode.markdownRepresentation()

        XCTAssertEqual("````Hello ``` world````", serialized)
    }

    func testThematicBreakSerialization() throws {
        let rootNode = ThematicBreak(variant: .dots) {}.makeNode()

        let serialized = try rootNode.markdownRepresentation()

        XCTAssertEqual("***\n", serialized)
    }

    func testHeadingSerialization() throws {
        let rootNode = Heading(level: 2) {
            Paragraph {
                Text.from("Hello world!")
            }
        }.makeNode()

        let serialized = try rootNode.markdownRepresentation()

        XCTAssertEqual("## Hello world!\n\n", serialized)
    }

    func testCodeBlockSerialization() throws {
        let rootNode = CodeBlock(language: "swift") {
            VerbatimText.from("func hello()")
        }.makeNode()

        let serialized = try rootNode.markdownRepresentation()

        XCTAssertEqual("```swift\nfunc hello()\n```\n", serialized)
    }

    func testContainerSerialization() throws {
        let rootNode = Container(variant: .blockquote) {
            Paragraph {
                Text.from("Hello\nworld!")
            }
            Paragraph {
                Text.from("Bla")
            }
        }.makeNode()

        let serialized = try rootNode.markdownRepresentation()

        XCTAssertEqual("> Hello\n> world!\n> \n> Bla\n> \n> \n", serialized)
    }

    func testOrdererListSerialization() throws {
        let rootNode = List(variant: .ordered) {
            ListItem(variant: .ordered) {
                Paragraph {
                    Text.from("Test")
                }
            }
            ListItem(variant: .ordered) {
                Paragraph {
                    Text.from("Bla")
                }
            }
        }.makeNode()

        let serialized = try rootNode.markdownRepresentation()

        XCTAssertEqual("1) Test\n1) Bla\n", serialized)
    }

    func testUnordererListSerialization() throws {
        let rootNode = List(variant: .unordered) {
            ListItem(variant: .unordered) {
                Paragraph {
                    Text.from("Test")
                }
            }
            ListItem(variant: .unordered) {
                Paragraph {
                    Text.from("Bla")
                }
            }
        }.makeNode()

        let serialized = try rootNode.markdownRepresentation()

        XCTAssertEqual("* Test\n* Bla\n", serialized)
    }

    func testTokenReaderSequence() throws {
//        let input: Substring = "##+##"
//        let tokens = Lexer().tokenize(string: input)
//        var reader = TokenReader(tokens: tokens)
//
//        let result = try reader.readUntil(encounteringSequence: [.plus, .hashtag], inclusive: false, allowEndOfFile: false)
//
//        for token in result {
//            print(token)
//        }
    }

    // TODO Build FunctionBuilder based testing framework where you define the expected AST and give it an input string

    static var allTests = [
        // TODO Add all test cases
        ("testParseParagraph", testTokenization),
    ]
}
