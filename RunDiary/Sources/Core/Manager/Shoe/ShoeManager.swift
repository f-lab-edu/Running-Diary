//
//  ShoeManager.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import SwiftData

final class ShoeManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllShoes() throws -> [ShoeModel] {
        let descriptor = FetchDescriptor<ShoeModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func addShoe(name: String, brand: String? = nil) throws {
        let shoe = ShoeModel(name: name, brand: brand)
        modelContext.insert(shoe)
        try modelContext.save()
    }

    func deleteShoe(_ shoe: ShoeModel) throws {
        modelContext.delete(shoe)
        try modelContext.save()
    }

    func initializeDefaultShoes() throws {
        let existingShoes = try fetchAllShoes()

        guard existingShoes.isEmpty else {
            return // 이미 신발이 있으면 초기화하지 않음
        }

        let defaultShoes = [
            ShoeModel(name: "Nike Pegasus 40", brand: "Nike"),
            ShoeModel(name: "Adidas Ultraboost 22", brand: "Adidas"),
            ShoeModel(name: "Asics Gel-Kayano 29", brand: "Asics"),
            ShoeModel(name: "New Balance 1080v12", brand: "New Balance"),
            ShoeModel(name: "Hoka Clifton 9", brand: "Hoka"),
            ShoeModel(name: "Brooks Ghost 15", brand: "Brooks"),
            ShoeModel(name: "On Cloudstratus 3", brand: "On")
        ]

        for shoe in defaultShoes {
            modelContext.insert(shoe)
        }

        try modelContext.save()
    }
}
