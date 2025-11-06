//
//  DataMapper.swift
//  RunDiary
//
//  Created by 김혜지 on 11/6/25.
//

import Foundation

enum DataMapper {
    static func encode(from data: Encodable, keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.keyEncodingStrategy = keyEncodingStrategy
        return try encoder.encode(data)
    }

    static func decode<T: Decodable>(from data: Data, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        return try decoder.decode(T.self, from: data)
    }
}
