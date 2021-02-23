//
//  Require.swift
//  
//
//  Created by Til Blechschmidt on 20.01.21.
//

import Foundation

internal func require(_ bool: Bool) throws {
    struct RequireError: Error {}
    guard bool else { throw RequireError() }
}
