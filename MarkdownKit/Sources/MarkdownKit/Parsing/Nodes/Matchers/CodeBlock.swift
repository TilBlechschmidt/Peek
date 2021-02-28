//
//  CodeBlock.swift
//  
//
//  Created by Til Blechschmidt on 26.02.21.
//

import Foundation

public struct CodeBlock: CustomDebugStringConvertible, Equatable, Node {
    public var debugDescription: String {
        "CodeBlock(language: \(language), content: \(content))"
    }

    public let language: Range<Substring.Index>
    public let content: Range<Substring.Index>

    public func allows(childMatcher: NodeMatcher) -> Bool {
        false
    }

    public func `continue`(on line: Line) -> Line? {
        nil
    }

    public struct Matcher: NodeMatcher {
        public func match(substring: Substring) -> NodeMatch? {
            guard let (markerCount, language, contentStart) = matchOpeningMarker(in: substring) else {
                return nil
            }

            // Find end of content (and consume closing marker)
            let (content, upperBound) = matchClosingMarker(in: substring[contentStart...], markerCount: markerCount)

            return (CodeBlock(language: language, content: content), upperBound)
        }

        private func matchOpeningMarker(in substring: Substring) -> (markerCount: Int, language: Range<Substring.Index>, upperBound: Substring.Index)? {
            guard substring.starts(with: "```") else {
                return nil
            }

            var markerCount = 0
            var upperBound = substring.startIndex
            var encounteredOtherCharacter = false
            for (index, character) in zip(substring.indices, substring) {
                if character == "`" {
                    markerCount += 1
                } else {
                    upperBound = index
                    encounteredOtherCharacter = true
                    break
                }
            }

            // Same hack as we did in Heading 🤷‍♂️
            // TODO Find a more generic method.
            if !encounteredOtherCharacter {
                upperBound = substring.endIndex
            }

            let languageStart = upperBound
            let languageEnd = substring[languageStart...].firstIndex(of: "\n") ?? substring.endIndex

            return (
                markerCount,
                languageStart..<languageEnd,
                upperBound: languageEnd == substring.endIndex ? languageEnd : substring.index(after: languageEnd)
            )
        }

        private func matchClosingMarker(in substring: Substring, markerCount: Int) -> (content: Range<Substring.Index>, upperBound: Substring.Index) {

            var upperBound = substring.startIndex
            var contentEnd = substring.startIndex
            var encounteredMarkerCount = 0
            var foundEndMarker = false

            for (index, character) in zip(substring.indices, substring) {
                if character == "`" {
                    encounteredMarkerCount += 1
                    continue
                } else if encounteredMarkerCount >= markerCount {
                    let endOfLine = substring[index...].firstIndex(of: "\n") ?? substring.endIndex

                    // Verify that the rest of the line is empty
                    if substring[index..<endOfLine].allSatisfy({ $0.isWhitespace }) {
                        foundEndMarker = true
                        upperBound = endOfLine
                        break
                    }
                }

                contentEnd = substring.index(after: index)
                encounteredMarkerCount = 0
            }

            // And another one of these hacks 🤷‍♂️
            if !foundEndMarker {
                upperBound = substring.endIndex
                contentEnd = encounteredMarkerCount >= markerCount ? contentEnd : substring.endIndex
            }

            return (substring.startIndex..<contentEnd, upperBound)
        }
    }
}
