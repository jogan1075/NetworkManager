//
//  Mappable.swift
//  NetworkManager
//
//  Created by Jonathan Muñoz on 06-04-25.
//

import Foundation

public protocol Mappable {
    associatedtype Input: Decodable
    associatedtype Output

    func map(_ input: Input) throws -> Output
}
