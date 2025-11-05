//
//  ShoeModel.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

public struct ShoeModel: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let brand: String

    public init(name: String, brand: String) {
        self.id = name.lowercased().replacingOccurrences(of: " ", with: "-")
        self.name = name
        self.brand = brand
    }
}
