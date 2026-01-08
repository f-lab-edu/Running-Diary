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

            // 2. Build (비즈니스 로직은 Client가 담당)
            return Self.merge(
                healthKitWorkouts: healthKitWorkouts,
                savedRecords: savedRecords,
                from: from,
                to: to
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

    private static func merge(
        healthKitWorkouts: [HealthKitWorkout],
        savedRecords: [RunningRecord],
        from: YearMonthDay,
        to: YearMonthDay
    ) -> [YearMonthDay: DailyRecord] {
        // 1. 날짜별 그룹핑
        let groupedHK = Dictionary(grouping: healthKitWorkouts, by: \.yearMonthDay)
        let groupedRecords = Dictionary(grouping: savedRecords, by: \.yearMonthDay)

        // 2. 요청 범위의 모든 날짜 생성
        let allDates = Self.generateDateRange(from: from, to: to)

        // 3. 각 날짜별로 DailyRecord 생성
        var result: [YearMonthDay: DailyRecord] = [:]
        for date in allDates {
            let saved = groupedRecords[date] ?? []
            let healthKit = groupedHK[date] ?? []

            // 4. 중복 제거: SwiftData에 저장된 것은 HealthKit에서 제외
            let filteredHealthKit = healthKit.filter { workout in
                !saved.contains(where: { $0.startTime == workout.startDate })
            }

            result[date] = DailyRecord(
                yearMonthDay: date,
                healthKitWorkouts: filteredHealthKit.sorted { $0.startDate < $1.startDate },
                savedRecords: saved
            )
        }

        return result
    }

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
