//
//  MarkdownKitTests.swift
//
//
//  Created by Til Blechschmidt on 21.01.21.
//

import XCTest
@testable import MarkdownKit

final class MarkdownKitTests: XCTestCase {
    func testParseParagraph() {
        let parser = Parser()
        let parsed = try! parser.parse("""
        # H1
        Hello world!

        A second paragraph!
        """)

        XCTAssertEqualMarkdown(parsed, [
            Heading(level: 1, rawContent: "H1"),
            Paragraph(text: "Hello world!"),
            Paragraph(text: "A second paragraph!")
        ])
    }

    static var allTests = [
        ("testParseParagraph", testParseParagraph),
    ]
}
