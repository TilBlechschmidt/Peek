//
//  UITableView+BlockCell.swift
//  Peek
//
//  Created by Til Blechschmidt on 07.03.21.
//

import UIKit
import MarkdownKit

extension BlockCell {
    static func reuseIdentifier(for content: Block.Content) -> String {
        switch content {
        case .text:
            return TextBlockCell.reuseIdentifier
        default:
            return BlockCell.reuseIdentifier
        }
    }
}

extension UITableView {
    func dequeueReusableCell(matching block: UIBlock, for indexPath: IndexPath) -> BlockCell? {
        return dequeueReusableCell(withIdentifier: BlockCell.reuseIdentifier(for: block.content), for: indexPath) as? BlockCell
    }
}
