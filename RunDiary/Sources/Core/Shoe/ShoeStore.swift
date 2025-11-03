//
//  ShoeStore.swift
//  RunDiary
//
//  Created by Claude on 10/21/25.
//

import Foundation

enum ShoeStoreError: LocalizedError, Equatable {
  case fetchFailed

  var errorDescription: String? {
    switch self {
    case .fetchFailed:
      return L10n.Shoe.Error.fetchFailed
    }
  }
}

final class ShoeStore: Sendable {
  static let shared = ShoeStore()

  private let shoes: [UUID: ShoeModel]

  private init() {
    let defaultShoes = [
        ShoeModel(name: "Nike Alphafly 3", brand: "Nike"),
        ShoeModel(name: "Nike Vaporfly 4", brand: "Nike"),
        ShoeModel(name: "Adidas Adizero Adios Pro 4", brand: "Adidas"),
        ShoeModel(name: "Adidas Adizero Evo SL", brand: "Adidas"),
        ShoeModel(name: "Asics Novablast 5", brand: "Asics"),
        ShoeModel(name: "Asics Metaspeed Sky Tokyo", brand: "Asics"),
        ShoeModel(name: "New Balance FuelCell SuperComp Trainer v2", brand: "New Balance"),
        ShoeModel(name: "Hoka Mach 6", brand: "Hoka"),
        ShoeModel(name: "Hoka Rocket X 3", brand: "Hoka"),
        ShoeModel(name: "Brooks Hyperion Max 3", brand: "Brooks"),
        ShoeModel(name: "Saucony Endorphin Elite 2", brand: "Saucony"),
        ShoeModel(name: "Saucony Endorphin Speed 5", brand: "Saucony"),
        ShoeModel(name: "Puma Fast-R Nitro Elite 3", brand: "Puma"),
        ShoeModel(name: "On Cloudboom Echo 3", brand: "On"),
        ShoeModel(name: "Mizuno Neo Zen", brand: "Mizuno")
    ]

    self.shoes = Dictionary(uniqueKeysWithValues: defaultShoes.map { ($0.id, $0) })
  }

  func fetchShoes() throws -> [ShoeModel] {
    // 현재는 항상 성공하지만, 나중에 서버 API로 전환시 실패 처리 가능
    return Array(shoes.values).sorted { $0.name < $1.name }
  }
}
