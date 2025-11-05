//
//  ShoeStorage.swift
//  RunDiary
//
//  Created by Claude on 10/21/25.
//

import Models

final class ShoeStorage: Sendable {
    static let shared = ShoeStorage()

    private(set) lazy var shoeDict: [String: ShoeModel] = Dictionary(uniqueKeysWithValues: shoes.map { ($0.id, $0) })

    private(set) lazy var shoes: [ShoeModel] = [
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

    private init() {}
}
