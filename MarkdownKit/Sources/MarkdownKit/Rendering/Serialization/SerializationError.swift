//
//  SerializationError.swift
//  
//
//  Created by Til Blechschmidt on 24.02.21.
//

import Foundation

enum SerializationError: Error {
    case childNotSerializable(NodeVariant)
}
