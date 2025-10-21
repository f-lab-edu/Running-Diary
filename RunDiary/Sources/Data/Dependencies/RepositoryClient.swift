//
//  RepositoryClient.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import Foundation
import SwiftData

import Dependencies
import DependenciesMacros

@DependencyClient
struct RepositoryClient {
    var fetch: @MainActor @Sendable (Date) async throws -> RunningRecord?
    var fetchRecords: @MainActor @Sendable (Date, Date) async throws -> [RunningRecord]
    var save: @MainActor @Sendable (RunningRecord) async throws -> Void
    var update: @MainActor @Sendable (RunningRecord) async throws -> Void
    var delete: @MainActor @Sendable (RunningRecord) async throws -> Void
}

extension RepositoryClient: DependencyKey {
    static let liveValue: RepositoryClient = RepositoryClient(
        fetch: { _ in
            fatalError("RepositoryClient.fetch must be overridden with live implementation")
        },
        fetchRecords: { _, _ in
            fatalError("RepositoryClient.fetchRecords must be overridden with live implementation")
        },
        save: { _ in
            fatalError("RepositoryClient.save must be overridden with live implementation")
        },
        update: { _ in
            fatalError("RepositoryClient.update must be overridden with live implementation")
        },
        delete: { _ in
            fatalError("RepositoryClient.delete must be overridden with live implementation")
        }
    )

    static let testValue = RepositoryClient(
        fetch: unimplemented("\(Self.self).fetch"),
        fetchRecords: unimplemented("\(Self.self).fetchRecords"),
        save: unimplemented("\(Self.self).save"),
        update: unimplemented("\(Self.self).update"),
        delete: unimplemented("\(Self.self).delete")
    )

    static let previewValue = RepositoryClient(
        fetch: { _ in
            RunningRecord(
                date: Date(),
                distanceInKilometers: 5.2,
                averagePace: "5'30\"",
                averageHeartRate: 155,
                averageCadence: 180,
                painAreas: [],
                runningStyle: "포어풋",
                condition: RunningCondition(
                    sleep: 7,
                    meal: true,
                    alcohol: false,
                    memo: "좋은 컨디션"
                ),
                shoes: "나이키 페가수스 40",
                weather: Weather(
                    temperature: 18.5,
                    humidity: 60,
                    windSpeed: 2.3
                ),
                satisfaction: nil,
                routeData: nil,
                hasMap: false
            )
        },
        fetchRecords: { _, _ in [] },
        save: { _ in },
        update: { _ in },
        delete: { _ in }
    )
}

extension DependencyValues {
    var repositoryClient: RepositoryClient {
        get { self[RepositoryClient.self] }
        set { self[RepositoryClient.self] = newValue }
    }
}

// MARK: - Helper

extension RepositoryClient {
    static func live(modelContext: ModelContext) -> RepositoryClient {
        let repository = SwiftDataRunningRecordRepository(modelContext: modelContext)

        return RepositoryClient(
            fetch: { date in
                try await repository.fetch(for: date)
            },
            fetchRecords: { startDate, endDate in
                try await repository.fetchRecords(from: startDate, to: endDate)
            },
            save: { record in
                try await repository.save(record)
            },
            update: { record in
                try await repository.update(record)
            },
            delete: { record in
                try await repository.delete(record)
            }
        )
    }
}
