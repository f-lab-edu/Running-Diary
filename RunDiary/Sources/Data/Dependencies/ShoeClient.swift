//
//  ShoeClient.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import Foundation
import ComposableArchitecture

@DependencyClient
struct ShoeClient {
    var fetchShoes: @Sendable () async throws -> [ShoeModel]
}

extension ShoeClient: DependencyKey {
    static let liveValue: ShoeClient = ShoeClient(
        fetchShoes: {
            try ShoeStore.shared.fetchShoes()
        }
    )

    static let testValue = ShoeClient(
        fetchShoes: unimplemented("\(Self.self).fetchShoes")
    )

    static let previewValue = ShoeClient(
        fetchShoes: {
            [
                ShoeModel(name: "Nike Pegasus 40", brand: "Nike"),
                ShoeModel(name: "Adidas Ultraboost 22", brand: "Adidas"),
                ShoeModel(name: "Asics Gel-Kayano 29", brand: "Asics")
            ]
        }
    )
}

extension DependencyValues {
    var shoeClient: ShoeClient {
        get { self[ShoeClient.self] }
        set { self[ShoeClient.self] = newValue }
    }
}
