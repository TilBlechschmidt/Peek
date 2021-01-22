//
//  HeaderTests.swift
//
//
//  Created by Til Blechschmidt on 21.01.21.
//

import XCTest
@testable import MarkdownKit

final class ThematicBreakTests: XCTestCase {
    func testSimpleBreaks() throws {
        let parser = Parser(blockTypes: [ThematicBreak.self])
        let parsed = try parser.parse("""
        ***
        ---
        ___
        """)

        XCTAssertEqualMarkdown(parsed, [
            ThematicBreak(variant: .dots),
            ThematicBreak(variant: .line),
            ThematicBreak(variant: .thickLine),
        ])
    }

    func testRejectsTooFewCharacters() {
        let parser = Parser(blockTypes: [ThematicBreak.self])
        XCTAssertThrowsError(try parser.parse("**"))
    }

    func testBreakWithLeadingWhitespaces() throws {
        let parser = Parser(blockTypes: [ThematicBreak.self])
        let parsed = try parser.parse("""
         ***
          ***
           ***
        """)

        XCTAssertEqualMarkdown(parsed, [
            ThematicBreak(variant: .dots),
            ThematicBreak(variant: .dots),
            ThematicBreak(variant: .dots),
        ])
    }

    func skip_testDoesNotParseTooManyLeadingWhitespaces() {
        let parser = Parser(blockTypes: [ThematicBreak.self])
        XCTAssertThrowsError(try parser.parse("     ***"))
    }

    static var allTests = [
        ("testSimpleBreaks", testSimpleBreaks),
        ("testBreakWithLeadingWhitespaces", testBreakWithLeadingWhitespaces)
    ]
}
