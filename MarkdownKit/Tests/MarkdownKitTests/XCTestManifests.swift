import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MarkdownKitTests.allTests),
        testCase(HeaderTests.allTests),
        testCase(ThematicBreakTests.allTests),
        testCase(LexerTests.allTests)
    ]
}
#endif
