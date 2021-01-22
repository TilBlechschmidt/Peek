//
//  HeaderTests.swift
//  
//
//  Created by Til Blechschmidt on 21.01.21.
//

import XCTest
@testable import MarkdownKit

final class HeaderTests: XCTestCase {
    func testParseDenseHeadings() throws {
        let parser = Parser(blockTypes: [Heading.self])
        let parsed = try parser.parse("""
        # H1
        ## H2
        ### H3
        """)

        XCTAssertEqualMarkdown(parsed, [
            Heading(level: 1, rawContent: "H1"),
            Heading(level: 2, rawContent: "H2"),
            Heading(level: 3, rawContent: "H3"),
        ])
    }

    func testParseLooseHeadings() throws {
        let parser = Parser(blockTypes: [Heading.self])
        let parsed = try parser.parse("""
        # H1

        ## H2

        ### H3
        """)

        XCTAssertEqualMarkdown(parsed, [
            Heading(level: 1, rawContent: "H1"),
            Heading(level: 2, rawContent: "H2"),
            Heading(level: 3, rawContent: "H3"),
        ])
    }

    func testValidHeadingLevels() {
        for i in (1..<7) {
            let hashtags = String(repeating: "#", count: i)
            var reader = Reader(string: "\(hashtags) Hello world")
            let heading = try! Heading.read(using: &reader)
            XCTAssertEqual(heading.level, i)
        }
    }

    func testInvalidHeadingLevels() {
        for i in [0, 7, 8] {
            let hashtags = String(repeating: "#", count: i)
            var reader = Reader(string: "\(hashtags) Hello world")
            XCTAssertThrowsError(try Heading.read(using: &reader))
        }
    }

    static var allTests = [
        ("testParseDenseHeadings", testParseDenseHeadings),
        ("testParseLooseHeadings", testParseLooseHeadings),
        ("testValidHeadingLevels", testValidHeadingLevels),
        ("testInvalidHeadingLevels", testInvalidHeadingLevels)
    ]
}
