//
//  CodeBlockTests.swift
//
//
//  Created by Til Blechschmidt on 21.01.21.
//

import XCTest
@testable import MarkdownKit

final class CodeBlockTests: XCTestCase {
//    func testCorrectCodeBlock() throws {
//        let parser = ParserOld(blockTypes: [CodeBlockOld.self])
//        let parsed = try parser.parse("""
//        ```swift
//        print("hello world")
//        ```
//        """)
//
//        XCTAssertEqualMarkdown(parsed, [
//            CodeBlockOld(variant: .backtick, delimiterCount: 3, infoString: "swift", code: "print(\"hello world\")")
//        ])
//    }
//
//    func testCodeBlockSurroundedByParagraph() throws {
//        let parser = ParserOld(blockTypes: [CodeBlockOld.self, ParagraphOld.self])
//        let parsed = try parser.parse("""
//        This is some test
//
//        ```swift
//        print("hello world")
//        ```
//
//        This is some test
//        """)
//
//        XCTAssertEqualMarkdown(parsed, [
//            ParagraphOld(text: "This is some test"),
//            CodeBlockOld(variant: .backtick, delimiterCount: 3, infoString: "swift", code: "print(\"hello world\")"),
//            ParagraphOld(text: "This is some test"),
//        ])
//    }
//
//    func testCodeBlockWithMissingCloseDelimiter() throws {
//        let parser = ParserOld(blockTypes: [CodeBlockOld.self])
//        let parsed = try parser.parse("""
//        ```swift
//        print("hello world")
//        """)
//
//        XCTAssertEqualMarkdown(parsed, [
//            CodeBlockOld(variant: .backtick, delimiterCount: 3, infoString: "swift", code: "print(\"hello world\")"),
//        ])
//    }
//
//    func testCodeBlockWithInvalidCharactersInInfoString() throws {
//        let parser = ParserOld(blockTypes: [CodeBlockOld.self])
//
//        XCTAssertThrowsError(
//            try parser.parse("""
//            ```swift`test
//            print("hello world")
//            ```
//            """)
//        )
//    }
//
//    func testDelimiterCountMatching() throws {
//        let parser = ParserOld(blockTypes: [CodeBlockOld.self])
//        let parsed = try parser.parse("""
//        ````swift
//        print("hello world")
//        ```
//        ````
//        """)
//
//        XCTAssertEqualMarkdown(parsed, [
//            CodeBlockOld(variant: .backtick, delimiterCount: 4, infoString: "swift", code: "print(\"hello world\")\n```"),
//        ])
//    }
//
//    static var allTests = [
//        ("testCorrectCodeBlock", testCorrectCodeBlock),
//        ("testCodeBlockSurroundedByParagraph", testCodeBlockSurroundedByParagraph),
//        ("testCodeBlockWithMissingCloseDelimiter", testCodeBlockWithMissingCloseDelimiter),
//        ("testCodeBlockWithInvalidCharactersInInfoString", testCodeBlockWithInvalidCharactersInInfoString),
//        ("testDelimiterCountMatching", testDelimiterCountMatching)
//    ]
}
