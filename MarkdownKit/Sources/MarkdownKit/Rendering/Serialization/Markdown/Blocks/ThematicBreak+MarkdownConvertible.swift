//
//  ThematicBreak+MarkdownConvertible
//  
//
//  Created by Til Blechschmidt on 24.02.21.
//

import Foundation

extension ThematicBreak: MarkdownConvertible {
    func markdownRepresentation(with serializedChildren: String) -> String {
        String(repeating: variant.tokenVariant.textRepresentation, count: 3) + "\n"
    }
}
