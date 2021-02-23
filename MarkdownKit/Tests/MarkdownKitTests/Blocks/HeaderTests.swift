//
//  HeaderTests.swift
//  
//
//  Created by Til Blechschmidt on 21.01.21.
//

import XCTest
@testable import MarkdownKit

final class HeaderTests: XCTestCase {
//    func testParseDenseHeadings() throws {
//        let parser = ParserOld(blockTypes: [HeadingOld.self])
//        let parsed = try parser.parse("""
//        # H1
//        ## H2
//        ### H3
//        """)
//
//        XCTAssertEqualMarkdown(parsed, [
//            HeadingOld(level: 1, rawContent: "H1"),
//            HeadingOld(level: 2, rawContent: "H2"),
//            HeadingOld(level: 3, rawContent: "H3"),
//        ])
//    }
//
//    func testParseLooseHeadings() throws {
//        let parser = ParserOld(blockTypes: [HeadingOld.self])
//        let parsed = try parser.parse("""
//        # H1
//
//        ## H2
//
//        ### H3
//        """)
//
//        XCTAssertEqualMarkdown(parsed, [
//            HeadingOld(level: 1, rawContent: "H1"),
//            HeadingOld(level: 2, rawContent: "H2"),
//            HeadingOld(level: 3, rawContent: "H3"),
//        ])
//    }
//
//    func testValidHeadingLevels() {
//        for i in (1..<7) {
//            let hashtags = String(repeating: "#", count: i)
//            var reader = Reader(string: "\(hashtags) Hello world")
//            let heading = try! HeadingOld.read(using: &reader)
//            XCTAssertEqual(heading.level, i)
//        }
//    }
//
//    func testInvalidHeadingLevels() {
//        for i in [0, 7, 8] {
//            let hashtags = String(repeating: "#", count: i)
//            var reader = Reader(string: "\(hashtags) Hello world")
//            XCTAssertThrowsError(try HeadingOld.read(using: &reader))
//        }
//    }
//
//    static var allTests = [
//        ("testParseDenseHeadings", testParseDenseHeadings),
//        ("testParseLooseHeadings", testParseLooseHeadings),
//        ("testValidHeadingLevels", testValidHeadingLevels),
//        ("testInvalidHeadingLevels", testInvalidHeadingLevels)
//    ]
}
