//
//  LiveRunningRecordClient.swift
//  RunDiary
//
//  Created by Claude on 11/29/25.
//

import ComposableArchitecture
import Foundation
import Models

@MainActor
final class LiveRunningRecordClient {
    private var cache: [YearMonth: [DailyRecord]] = [:]

    @Dependency(\.healthKitClient) private var healthKitClient
    @Dependency(\.swiftDataClient) private var swiftDataClient

    init() {}

    func fetchData(from: YearMonthDay, to: YearMonthDay) async throws -> [YearMonthDay: DailyRecord] {
        let requiredMonths = calculateMonthsInRange(from: from, to: to)
        let monthsToFetch = requiredMonths.filter { !cache.keys.contains($0) }

        for month in monthsToFetch {
            try await fetchAndCacheMonth(month)
        }

        return extractDailyRecordsFromCache(from: from, to: to)
    }

    func saveRecord(_ record: RunningRecord) async throws {
        try await swiftDataClient.save(record)
        let month = record.yearMonthDay.toYearMonth()
        cache.removeValue(forKey: month)
    }

    func clearCache() {
        cache.removeAll()
    }

    // MARK: - Private Methods

    private func calculateMonthsInRange(from: YearMonthDay, to: YearMonthDay) -> [YearMonth] {
        var months: [YearMonth] = []
        var current = from.toYearMonth()
        let end = to.toYearMonth()

        while current <= end {
            months.append(current)

            // Move to next month
            if current.month == 12 {
                current = YearMonth(year: current.year + 1, month: 1)
            } else {
                current = YearMonth(year: current.year, month: current.month + 1)
            }
        }

        return months
    }

    private func fetchAndCacheMonth(_ month: YearMonth) async throws {
        let (startDate, endDate) = calculateMonthBoundaries(month)

        async let healthKitWorkouts = try healthKitClient.fetchRunningDataBetweenDates(
            startDate.toDate(),
            endDate.toDate()
        )
        async let savedRecords = try swiftDataClient.fetchRecords(
            startDate.toDate(),
            endDate.toDate()
        )

        let hkWorkouts = try await healthKitWorkouts
        let records = try await savedRecords

        let groupedHK = Dictionary(grouping: hkWorkouts, by: \.yearMonthDay)
        let groupedRecords = Dictionary(grouping: records, by: \.yearMonthDay)

        let dailyRecords = createDailyRecordsForMonth(
            month: month,
            healthKitWorkouts: groupedHK,
            savedRecords: groupedRecords
        )

        cache[month] = dailyRecords
    }

    private func createDailyRecordsForMonth(
        month: YearMonth,
        healthKitWorkouts: [YearMonthDay: [HealthKitWorkout]],
        savedRecords: [YearMonthDay: [RunningRecord]]
    ) -> [DailyRecord] {
        let datesInMonth = generateAllDatesInMonth(month)

        return datesInMonth.map { date in
            let saved = savedRecords[date] ?? []
            let healthKit = healthKitWorkouts[date] ?? []

            let filteredHealthKit = healthKit.filter { workout in
                !saved.contains(where: { $0.startTime == workout.startDate })
            }

            let sortedHealthKit = filteredHealthKit.sorted { $0.startDate < $1.startDate }

            return DailyRecord(
                yearMonthDay: date,
                healthKitWorkouts: sortedHealthKit,
                savedRecords: saved
            )
        }
    }

    private func extractDailyRecordsFromCache(
        from: YearMonthDay,
        to: YearMonthDay
    ) -> [YearMonthDay: DailyRecord] {
        var result: [YearMonthDay: DailyRecord] = [:]

        for (_, dailyRecords) in cache {
            for record in dailyRecords where record.yearMonthDay >= from && record.yearMonthDay <= to {
                result[record.yearMonthDay] = record
            }
        }

        return result
    }

    private func calculateMonthBoundaries(_ month: YearMonth) -> (start: YearMonthDay, end: YearMonthDay) {
        let start = YearMonthDay(year: month.year, month: month.month, day: 1)
        let lastDay = Calendar.current.range(of: .day, in: .month, for: start.toDate())!.count
        let end = YearMonthDay(year: month.year, month: month.month, day: lastDay)
        return (start, end)
    }

    private func generateAllDatesInMonth(_ month: YearMonth) -> [YearMonthDay] {
        let start = YearMonthDay(year: month.year, month: month.month, day: 1)
        let lastDay = Calendar.current.range(of: .day, in: .month, for: start.toDate())!.count

        return (1...lastDay).map { day in
            YearMonthDay(year: month.year, month: month.month, day: day)
        }
    }
}
