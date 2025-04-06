//
//  DecodingError+.swift
//  NetworkManager
//
//  Created by Jonathan Muñoz on 06-04-25.
//
import Foundation

extension DecodingError {
    var detailErrorDescription: String {
        switch self {
        case let .typeMismatch(type, context):
            return "Type \(type) mismatch: \(context.debugDescription)"
        case let .valueNotFound(type, context):
            return "Type \(type) value not found: \(context.debugDescription)"
        case let .keyNotFound(codingKey, context):
            return "Key \(codingKey) not found: \(context.debugDescription)"
        case let .dataCorrupted(context):
            return "Data corrupted: \(context.debugDescription)"
        @unknown default:
            return "Unknown case"
        }
    }
}
