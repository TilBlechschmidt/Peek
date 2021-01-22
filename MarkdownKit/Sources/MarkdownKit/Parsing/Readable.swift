//
//  File.swift
//  
//
//  Created by Til Blechschmidt on 20.01.21.
//

import Foundation

internal protocol Readable {
    static func read(using reader: inout Reader) throws -> Self
}

extension Readable {
    static func readOrRewind(using reader: inout Reader) throws -> Self {
        guard reader.previousCharacter != "\\" else {
            throw Reader.Error()
        }

        let previousReader = reader

        do {
            return try read(using: &reader)
        } catch {
            reader = previousReader
            throw error
        }
    }
}
