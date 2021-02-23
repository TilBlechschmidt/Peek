import XCTest

import MarkdownKitTests

var tests = [XCTestCaseEntry]()
tests += MarkdownKitTests.allTests()
tests += HeaderTests.allTests()
tests += ThematicBreakTests.allTests()
tests += LexerTests.allTests()
XCTMain(tests)
