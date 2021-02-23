//
//  Container+MarkdownConvertible.swift
//  
//
//  Created by Til Blechschmidt on 24.02.21.
//

import Foundation

extension Container: MarkdownConvertible {
    func markdownRepresentation(with serializedChildren: String) -> String {
        // TODO When containing a paragraph, this creates two trailing lines with just "> \n"
        //      Even though this is correct according to the spec, they are redundant.
        //      Could be fixed by trimming trailing newlines from serializedChildren before replacing them
        "\(variant.marker.textRepresentation) " + serializedChildren.replacingOccurrences(of: "\n", with: "\n\(variant.marker.textRepresentation) ") + "\n"
    }
}
