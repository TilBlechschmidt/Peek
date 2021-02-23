//
//  VariantRestriction.swift
//  
//
//  Created by Til Blechschmidt on 21.02.21.
//

import Foundation

enum VariantRestriction {
    case blacklist([NodeVariant.Type])
    case whitelist([NodeVariant.Type])
    case closure((NodeVariant) -> Bool)

    func union(_ other: Self) -> Self {
        .closure({
            return self.allows(variant: $0) || other.allows(variant: $0)
        })
    }

    func intersection(_ other: Self) -> Self {
        .closure({
            return self.allows(variant: $0) && other.allows(variant: $0)
        })
    }

    func allows(variant: NodeVariant) -> Bool {
        switch self {
        case .blacklist(let blacklist):
            return !blacklist.contains { $0 == type(of: variant) }
        case .whitelist(let whitelist):
            return whitelist.contains { $0 == type(of: variant) }
        case .closure(let closure):
            return closure(variant)
        }
    }
}

extension VariantRestriction {
    static var indifferent: VariantRestriction {
        .blacklist([])
    }

    static var disallowAll: VariantRestriction {
        .whitelist([])
    }

    static var inlineVariants: VariantRestriction {
        .closure({
            return $0 as? InlineNodeVariant != nil
        })
    }
}
