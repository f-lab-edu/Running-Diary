//
//  RunningRecordClient.swift
//  RunDiary
//
//  Created by Claude on 11/29/25.
//

import ComposableArchitecture
import Foundation
import Models

@DependencyClient
struct RunningRecordClient {
    var fetchData: @MainActor @Sendable (_ from: YearMonthDay, _ to: YearMonthDay) async throws -> [YearMonthDay: DailyRecord]
    var saveRecord: @MainActor @Sendable (_ record: RunningRecord) async throws -> Void
    var updateRecord: @MainActor @Sendable (_ record: RunningRecord) async throws -> Void
    var clearCache: @MainActor @Sendable () -> Void
}

extension RunningRecordClient: DependencyKey {
    static let liveValue: RunningRecordClient = RunningRecordClient(
        fetchData: { from, to in
            @Dependency(\.healthKitClient) var healthKitClient
            @Dependency(\.swiftDataClient) var swiftDataClient

            try await healthKitClient.ensureAuthorizationIfNeeded()

            // 1. Fetch (캐싱은 Repository가 담당)
            let healthKitWorkouts = try await healthKitClient.fetchRunningDataBetweenDates(
                from.toDate(),
                to.toDate()
            )
            let savedRecords = try await swiftDataClient.fetchRecords(
                from.toDate(),
                to.toDate()
            )

            // 2. Build (비즈니스 로직은 DailyRecord가 담당)
            return DailyRecord.build(
                from: healthKitWorkouts,
                savedRecords: savedRecords,
                dateRange: from...to
            )
        },
        saveRecord: { record in
            @Dependency(\.swiftDataClient) var swiftDataClient
            try await swiftDataClient.save(record)
        },
        updateRecord: { record in
            @Dependency(\.swiftDataClient) var swiftDataClient
            try await swiftDataClient.update(record)
        },
        clearCache: {
            @Dependency(\.swiftDataClient) var swiftDataClient
            swiftDataClient.clearCache()
        }
    )

    static let testValue = RunningRecordClient(
        fetchData: unimplemented("\(Self.self).fetchData"),
        saveRecord: unimplemented("\(Self.self).saveRecord"),
        updateRecord: unimplemented("\(Self.self).updateRecord"),
        clearCache: unimplemented("\(Self.self).clearCache")
    )

    static let previewValue = RunningRecordClient(
        fetchData: { from, to in
            let dates = Self.generateDateRange(from: from, to: to)
            return Dictionary(uniqueKeysWithValues: dates.map { date in
                (date, DailyRecord(
                    yearMonthDay: date,
                    healthKitWorkouts: [],
                    savedRecords: []
                ))
            })
        },
        saveRecord: { _ in },
        updateRecord: { _ in },
        clearCache: { }
    )

    private static func generateDateRange(from: YearMonthDay, to: YearMonthDay) -> [YearMonthDay] {
        var dates: [YearMonthDay] = []
        var current = from

        while current <= to {
            dates.append(current)
            guard let next = current.add(day: 1) else { break }
            current = next
        }

        return dates
    }
}

extension DependencyValues {
    var runningRecordClient: RunningRecordClient {
        get { self[RunningRecordClient.self] }
        set { self[RunningRecordClient.self] = newValue }
    }
}
