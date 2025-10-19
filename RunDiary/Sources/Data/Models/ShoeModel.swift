//
//  ShoeModel.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import SwiftData

@Model
final class ShoeModel: @unchecked Sendable {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.createdAt = createdAt
    }
}
