//
//  VariantRestriction.swift
//  
//
//  Created by Til Blechschmidt on 21.02.21.
//

import Foundation

public enum VariantRestriction {
    case blacklist([NodeVariant.Type])
    case whitelist([NodeVariant.Type])
    case closure((NodeVariant) -> Bool)

    public func union(_ other: Self) -> Self {
        .closure({
            return self.allows(variant: $0) || other.allows(variant: $0)
        })
    }

    public func intersection(_ other: Self) -> Self {
        .closure({
            return self.allows(variant: $0) && other.allows(variant: $0)
        })
    }

    public func allows(variant: NodeVariant) -> Bool {
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
    public static var indifferent: VariantRestriction {
        .blacklist([])
    }

    public static var disallowAll: VariantRestriction {
        .whitelist([])
    }

    public static var inlineVariants: VariantRestriction {
        .closure({
            return $0 as? InlineNodeVariant != nil
        })
    }
}
