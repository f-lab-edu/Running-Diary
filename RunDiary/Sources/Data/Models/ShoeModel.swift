//
//  ShoeModel.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

struct ShoeModel: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let name: String
    let brand: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
    }
}
