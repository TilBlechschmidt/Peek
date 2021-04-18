//
//  Color.swift
//  Peek
//
//  Created by Til Blechschmidt on 28.02.21.
//

import SwiftUI

extension Color {
    static var background: Self {
        Color("Background")
    }

    static var blockquote: Self {
        Color("Blockquote")
    }
}

extension UIColor {
    private static var unknownColor: UIColor {
        print("WARNING: Attempted to load non-existent color!")
        return .systemPink
    }

    static var background: UIColor {
        UIColor(named: "Background") ?? .unknownColor
    }

    static var blockquote: UIColor {
        UIColor(named: "Blockquote") ?? .unknownColor
    }

    static var accentColor: UIColor {
        UIColor(named: "AccentColor") ?? .unknownColor
    }

    static var selection: UIColor {
        UIColor(named: "Selection") ?? .unknownColor
    }

    static var interaction: UIColor {
        UIColor(named: "Interaction") ?? .unknownColor
    }
}
