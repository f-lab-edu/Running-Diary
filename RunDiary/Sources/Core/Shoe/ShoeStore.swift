//
//  ShoeStore.swift
//  RunDiary
//
//  Created by Claude on 10/21/25.
//

import Foundation

enum ShoeStoreError: LocalizedError {
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return String(localized: "shoe.error.fetch_failed")
        }
    }
}

final class ShoeStore: Sendable {
    static let shared = ShoeStore()

    private let shoes: [UUID: ShoeModel]

    private init() {
        let defaultShoes = [
            ShoeModel(name: "Nike Pegasus 40", brand: "Nike"),
            ShoeModel(name: "Adidas Ultraboost 22", brand: "Adidas"),
            ShoeModel(name: "Asics Gel-Kayano 29", brand: "Asics"),
            ShoeModel(name: "New Balance 1080v12", brand: "New Balance"),
            ShoeModel(name: "Hoka Clifton 9", brand: "Hoka"),
            ShoeModel(name: "Brooks Ghost 15", brand: "Brooks"),
            ShoeModel(name: "On Cloudstratus 3", brand: "On")
        ]

        self.shoes = Dictionary(uniqueKeysWithValues: defaultShoes.map { ($0.id, $0) })
    }

    func fetchShoes() throws -> [ShoeModel] {
        // 현재는 항상 성공하지만, 나중에 서버 API로 전환시 실패 처리 가능
        return Array(shoes.values).sorted { $0.name < $1.name }
    }
}
