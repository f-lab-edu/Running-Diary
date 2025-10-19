//
//  ShoeClient.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import Foundation
import SwiftData
import ComposableArchitecture

@DependencyClient
struct ShoeClient {
    var fetchAllShoes: @Sendable () async throws -> [ShoeModel]
    var addShoe: @Sendable (String, String?) async throws -> Void
    var deleteShoe: @Sendable (ShoeModel) async throws -> Void
    var initializeDefaultShoes: @Sendable () async throws -> Void
}

extension ShoeClient: DependencyKey {
    static let liveValue: ShoeClient = ShoeClient(
        fetchAllShoes: {
            fatalError("ShoeClient.fetchAllShoes must be overridden with live implementation")
        },
        addShoe: { _, _ in
            fatalError("ShoeClient.addShoe must be overridden with live implementation")
        },
        deleteShoe: { _ in
            fatalError("ShoeClient.deleteShoe must be overridden with live implementation")
        },
        initializeDefaultShoes: {
            fatalError("ShoeClient.initializeDefaultShoes must be overridden with live implementation")
        }
    )

    static let testValue = ShoeClient(
        fetchAllShoes: unimplemented("\(Self.self).fetchAllShoes"),
        addShoe: unimplemented("\(Self.self).addShoe"),
        deleteShoe: unimplemented("\(Self.self).deleteShoe"),
        initializeDefaultShoes: unimplemented("\(Self.self).initializeDefaultShoes")
    )

    static let previewValue = ShoeClient(
        fetchAllShoes: {
            [
                ShoeModel(name: "Nike Pegasus 40", brand: "Nike"),
                ShoeModel(name: "Adidas Ultraboost 22", brand: "Adidas"),
                ShoeModel(name: "Asics Gel-Kayano 29", brand: "Asics")
            ]
        },
        addShoe: { _, _ in },
        deleteShoe: { _ in },
        initializeDefaultShoes: {}
    )
}

extension DependencyValues {
    var shoeClient: ShoeClient {
        get { self[ShoeClient.self] }
        set { self[ShoeClient.self] = newValue }
    }
}

// MARK: - Helper

extension ShoeClient {
    static func live(modelContext: ModelContext) -> ShoeClient {
        let manager = ShoeManager(modelContext: modelContext)

        return ShoeClient(
            fetchAllShoes: {
                try manager.fetchAllShoes()
            },
            addShoe: { name, brand in
                try manager.addShoe(name: name, brand: brand)
            },
            deleteShoe: { shoe in
                try manager.deleteShoe(shoe)
            },
            initializeDefaultShoes: {
                try manager.initializeDefaultShoes()
            }
        )
    }
}
