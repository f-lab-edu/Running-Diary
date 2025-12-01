//
//  RunningRecordClientTests.swift
//  RunDiaryTests
//
//  Created by Claude on 11/29/25.
//

import ComposableArchitecture
import Foundation
import Models

import Testing

@testable import RunDiary

@Suite("RunningRecordClient")
@MainActor
struct RunningRecordClientTests {

    // MARK: - Cache Hit Tests

    @Test("fetchData는 캐시 히트 시 의존성 호출 안 함")
    func fetchData_withCacheHit_doesNotCallDependencies() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)
        let expectedWorkout = makeHealthKitWorkout(yearMonthDay: testDate)
        let expectedRecord = makeRunningRecord(yearMonthDay: testDate)

        var fetchCount = 0
        let client = makeTestClient(
            healthKitWorkouts: [expectedWorkout],
            savedRecords: [expectedRecord],
            onFetch: { _ in fetchCount += 1 }
        )

        // When - First fetch (cache miss)
        let firstResult = try await client.fetchData(testDate, testDate)

        // Then - Should call dependencies
        #expect(fetchCount == 1)
        #expect(firstResult.count == 1)
        #expect(firstResult[testDate]?.savedRecords.count == 1)

        // When - Second fetch (cache hit)
        let secondResult = try await client.fetchData(testDate, testDate)

        // Then - Should NOT call dependencies again
        #expect(fetchCount == 1)
        #expect(secondResult.count == 1)
        #expect(secondResult[testDate]?.savedRecords.count == 1)
    }

    @Test("fetchData는 부분 캐시 히트 시 누락된 월만 조회")
    func fetchData_withPartialCacheHit_fetchesOnlyMissingMonths() async throws {
        // Given
        let januaryDate = makeYearMonthDay(month: 1, day: 15)
        let februaryDate = makeYearMonthDay(month: 2, day: 15)

        var fetchedMonths: Set<Int> = []
        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: [],
            onFetch: { months in
                fetchedMonths.formUnion(months)
            }
        )

        // When - First fetch January
        _ = try await client.fetchData(januaryDate, januaryDate)

        // Then - Should fetch January
        #expect(fetchedMonths.contains(1))

        fetchedMonths.removeAll()

        // When - Fetch January to February (January cached, February not)
        _ = try await client.fetchData(januaryDate, februaryDate)

        // Then - Should only fetch February
        #expect(!fetchedMonths.contains(1))
        #expect(fetchedMonths.contains(2))
    }

    @Test("fetchData는 같은 월의 다른 범위 조회 시 캐시 사용")
    func fetchData_withDifferentRangesInSameMonth_usesCache() async throws {
        // Given
        let start = makeYearMonthDay(month: 1, day: 1)
        let middle = makeYearMonthDay(month: 1, day: 15)
        let end = makeYearMonthDay(month: 1, day: 31)

        var fetchCount = 0
        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: [],
            onFetch: { _ in fetchCount += 1 }
        )

        // When - Fetch first half of month
        _ = try await client.fetchData(start, middle)

        // Then
        #expect(fetchCount == 1)

        // When - Fetch second half of month
        _ = try await client.fetchData(middle, end)

        // Then - Should use cached data
        #expect(fetchCount == 1)
    }

    // MARK: - Deduplication Tests

    @Test("HealthKit 데이터 중복 필터링 - startDate 일치")
    func fetchData_filtersHealthKitWorkouts_whenStartDateMatchesSavedRecord() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)
        let startTime = testDate.toDate()

        let healthKitWorkout = makeHealthKitWorkout(yearMonthDay: testDate, startTime: startTime)
        let savedRecord = makeRunningRecord(yearMonthDay: testDate, startTime: startTime)

        let client = makeTestClient(
            healthKitWorkouts: [healthKitWorkout],
            savedRecords: [savedRecord]
        )

        // When
        let result = try await client.fetchData(testDate, testDate)

        // Then - HealthKit workout should be filtered out
        let dailyRecord = result[testDate]
        #expect(dailyRecord?.savedRecords.count == 1)
        #expect(dailyRecord?.healthKitWorkouts.isEmpty == true)
    }

    @Test("HealthKit 데이터 보존 - startDate 불일치")
    func fetchData_keepsHealthKitWorkouts_whenStartDateDifferent() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)

        let healthKitWorkout = makeHealthKitWorkout(
            yearMonthDay: testDate,
            startTime: testDate.toDate().addingTimeInterval(1000)  // Different time
        )
        let savedRecord = makeRunningRecord(
            yearMonthDay: testDate,
            startTime: testDate.toDate()
        )

        let client = makeTestClient(
            healthKitWorkouts: [healthKitWorkout],
            savedRecords: [savedRecord]
        )

        // When
        let result = try await client.fetchData(testDate, testDate)

        // Then - Both should be present
        let dailyRecord = result[testDate]
        #expect(dailyRecord?.savedRecords.count == 1)
        #expect(dailyRecord?.healthKitWorkouts.count == 1)
    }

    @Test("여러 RunningRecord가 여러 HealthKit 데이터 필터링")
    func fetchData_filtersMultipleHealthKitWorkouts_withMultipleSavedRecords() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)
        let startTime1 = testDate.toDate()
        let startTime2 = testDate.toDate().addingTimeInterval(3600)
        let startTime3 = testDate.toDate().addingTimeInterval(7200)

        let healthKit1 = makeHealthKitWorkout(yearMonthDay: testDate, startTime: startTime1)
        let healthKit2 = makeHealthKitWorkout(yearMonthDay: testDate, startTime: startTime2)
        let healthKit3 = makeHealthKitWorkout(yearMonthDay: testDate, startTime: startTime3)

        let saved1 = makeRunningRecord(yearMonthDay: testDate, startTime: startTime1)
        let saved2 = makeRunningRecord(yearMonthDay: testDate, startTime: startTime2)

        let client = makeTestClient(
            healthKitWorkouts: [healthKit1, healthKit2, healthKit3],
            savedRecords: [saved1, saved2]
        )

        // When
        let result = try await client.fetchData(testDate, testDate)

        // Then - Only healthKit3 should remain (others filtered)
        let dailyRecord = result[testDate]
        #expect(dailyRecord?.savedRecords.count == 2)
        #expect(dailyRecord?.healthKitWorkouts.count == 1)
        #expect(dailyRecord?.healthKitWorkouts.first?.startDate == startTime3)
    }

    // MARK: - Cache Invalidation Tests

    @Test("saveRecord는 해당 월의 캐시 무효화")
    func saveRecord_invalidatesMonthCache() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)
        let initialWorkout = makeHealthKitWorkout(yearMonthDay: testDate)

        var fetchCount = 0
        let client = makeTestClient(
            healthKitWorkouts: [initialWorkout],
            savedRecords: [],
            onFetch: { _ in fetchCount += 1 }
        )

        // When - Initial fetch to populate cache
        _ = try await client.fetchData(testDate, testDate)
        #expect(fetchCount == 1)

        // When - Save a record in the same month
        let recordToSave = makeRunningRecord(yearMonthDay: testDate)
        try await client.saveRecord(recordToSave)

        // When - Fetch again
        _ = try await client.fetchData(testDate, testDate)

        // Then - Should refetch because cache was invalidated
        #expect(fetchCount == 2)
    }

    @Test("saveRecord는 다른 월의 캐시는 유지")
    func saveRecord_preservesOtherMonthsCaches() async throws {
        // Given
        let januaryDate = makeYearMonthDay(month: 1, day: 15)
        let februaryDate = makeYearMonthDay(month: 2, day: 15)

        var fetchedMonths: Set<Int> = []
        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: [],
            onFetch: { months in
                fetchedMonths.formUnion(months)
            }
        )

        // When - Fetch January and February to populate cache
        _ = try await client.fetchData(januaryDate, februaryDate)
        #expect(fetchedMonths.contains(1))
        #expect(fetchedMonths.contains(2))

        fetchedMonths.removeAll()

        // When - Save a record in January
        let recordToSave = makeRunningRecord(yearMonthDay: januaryDate)
        try await client.saveRecord(recordToSave)

        // When - Fetch both months again
        _ = try await client.fetchData(januaryDate, februaryDate)

        // Then - Only January should be refetched
        #expect(fetchedMonths.contains(1))
        #expect(!fetchedMonths.contains(2))
    }

    @Test("clearCache는 모든 캐시 제거")
    func clearCache_removesAllCachedData() async throws {
        // Given
        let januaryDate = makeYearMonthDay(month: 1, day: 15)
        let februaryDate = makeYearMonthDay(month: 2, day: 15)

        var fetchCount = 0
        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: [],
            onFetch: { _ in fetchCount += 1 }
        )

        // When - Fetch to populate cache (January + February = 2 months = 2 fetches)
        _ = try await client.fetchData(januaryDate, februaryDate)
        #expect(fetchCount == 2, "First fetch should fetch 2 months, but got \(fetchCount)")

        // When - Clear cache
        client.clearCache()

        // When - Fetch again (should refetch both months)
        _ = try await client.fetchData(januaryDate, februaryDate)

        // Then - Should refetch both months (total: 2 + 2 = 4)
        #expect(fetchCount == 4, "After clearing cache, second fetch should refetch 2 months (total 4), but fetchCount is \(fetchCount)")
    }

    // MARK: - Month-based Caching Tests

    @Test("fetchData는 전체 월을 캐시함")
    func fetchData_cachesEntireMonth() async throws {
        // Given
        let day15 = makeYearMonthDay(month: 1, day: 15)

        var fetchCount = 0
        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: [],
            onFetch: { _ in fetchCount += 1 }
        )

        // When - Fetch only day 15
        let firstResult = try await client.fetchData(day15, day15)

        // Then - Should fetch entire month
        #expect(fetchCount == 1)
        #expect(firstResult.count == 1)

        // When - Fetch day 1 to 31 (entire month)
        let day1 = makeYearMonthDay(month: 1, day: 1)
        let day31 = makeYearMonthDay(month: 1, day: 31)
        let secondResult = try await client.fetchData(day1, day31)

        // Then - Should use cache (entire month was cached from first fetch)
        #expect(fetchCount == 1)
        #expect(secondResult.count == 31)
    }

    @Test("fetchData는 여러 월에 걸친 범위 조회")
    func fetchData_handlesMultiMonthRange() async throws {
        // Given
        let januaryEnd = makeYearMonthDay(month: 1, day: 31)
        let februaryStart = makeYearMonthDay(month: 2, day: 1)

        var fetchedMonths: Set<Int> = []
        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: [],
            onFetch: { months in
                fetchedMonths.formUnion(months)
            }
        )

        // When
        let result = try await client.fetchData(januaryEnd, februaryStart)

        // Then - Should fetch both months
        #expect(fetchedMonths.contains(1))
        #expect(fetchedMonths.contains(2))
        #expect(result.count == 2)
    }

    // MARK: - Edge Cases

    @Test("빈 데이터 처리 - HealthKit과 SwiftData 모두 빈 배열")
    func fetchData_handlesEmptyDataFromBothSources() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)

        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: []
        )

        // When
        let result = try await client.fetchData(testDate, testDate)

        // Then
        let dailyRecord = result[testDate]
        #expect(dailyRecord?.healthKitWorkouts.isEmpty == true)
        #expect(dailyRecord?.savedRecords.isEmpty == true)
        #expect(dailyRecord?.hasAnyData == false)
    }

    @Test("HealthKit만 데이터 있음")
    func fetchData_handlesOnlyHealthKitData() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)
        let healthKitWorkout = makeHealthKitWorkout(yearMonthDay: testDate)

        let client = makeTestClient(
            healthKitWorkouts: [healthKitWorkout],
            savedRecords: []
        )

        // When
        let result = try await client.fetchData(testDate, testDate)

        // Then
        let dailyRecord = result[testDate]
        #expect(dailyRecord?.healthKitWorkouts.count == 1)
        #expect(dailyRecord?.savedRecords.isEmpty == true)
        #expect(dailyRecord?.hasAnyData == true)
    }

    @Test("SwiftData만 데이터 있음")
    func fetchData_handlesOnlySwiftDataData() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)
        let savedRecord = makeRunningRecord(yearMonthDay: testDate)

        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: [savedRecord]
        )

        // When
        let result = try await client.fetchData(testDate, testDate)

        // Then
        let dailyRecord = result[testDate]
        #expect(dailyRecord?.healthKitWorkouts.isEmpty == true)
        #expect(dailyRecord?.savedRecords.count == 1)
        #expect(dailyRecord?.hasAnyData == true)
    }
}

// MARK: - Test Helpers

private extension RunningRecordClientTests {
    /// YearMonthDay 생성 헬퍼
    func makeYearMonthDay(
        year: Int? = nil,
        month: Int = 1,
        day: Int = 1
    ) -> YearMonthDay {
        let calendar = Calendar.current
        let currentYear = year ?? calendar.component(.year, from: Date())
        return YearMonthDay(year: currentYear, month: month, day: day)
    }

    /// HealthKitWorkout 생성 헬퍼
    func makeHealthKitWorkout(
        yearMonthDay: YearMonthDay,
        distance: Double = 5.0,
        startTime: Date? = nil
    ) -> HealthKitWorkout {
        let start = startTime ?? yearMonthDay.toDate()
        return HealthKitWorkout(
            distance: distance,
            duration: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            routeData: nil,
            startDate: start,
            endDate: start.addingTimeInterval(1800)
        )
    }

    /// RunningRecord 생성 헬퍼
    func makeRunningRecord(
        yearMonthDay: YearMonthDay,
        distance: Double = 5.0,
        startTime: Date? = nil
    ) -> RunningRecord {
        let start = startTime ?? yearMonthDay.toDate()
        return RunningRecord(
            yearMonthDay: yearMonthDay,
            distanceInKilometers: distance,
            durationInSeconds: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            runningStyle: .midfoot,
            startTime: start,
            endTime: start.addingTimeInterval(1800)
        )
    }

    /// 테스트용 RunningRecordClient 생성
    @MainActor
    func makeTestClient(
        healthKitWorkouts: [HealthKitWorkout] = [],
        savedRecords: [RunningRecord] = [],
        onFetch: @escaping ([Int]) -> Void = { _ in }
    ) -> RunningRecordClient {
        withDependencies {
            $0.healthKitClient.fetchRunningDataBetweenDates = { startDate, endDate in
                // Track which months were fetched
                let startMonth = Calendar.current.component(.month, from: startDate)
                let endMonth = Calendar.current.component(.month, from: endDate)

                var months: [Int] = []
                for month in startMonth...endMonth {
                    months.append(month)
                }
                onFetch(months)

                // Return filtered workouts for date range
                return healthKitWorkouts.filter { workout in
                    workout.startDate >= startDate && workout.startDate <= endDate
                }
            }

            $0.swiftDataClient.fetchRecords = { startDate, endDate in
                // Return filtered records for date range
                savedRecords.filter { record in
                    let recordDate = record.startTime
                    return recordDate >= startDate && recordDate <= endDate
                }
            }

            $0.swiftDataClient.save = { _ in }
            $0.swiftDataClient.update = { _ in }
        } operation: {
            // Create a fresh LiveRunningRecordClient instance for each test
            // This ensures test isolation and uses the mocked dependencies from withDependencies
            let cache = LiveRunningRecordClient()
            return RunningRecordClient(
                fetchData: { from, to in
                    try await cache.fetchData(from: from, to: to)
                },
                saveRecord: { record in
                    try await cache.saveRecord(record)
                },
                updateRecord: { record in
                    try await cache.updateRecord(record)
                },
                clearCache: {
                    cache.clearCache()
                }
            )
        }
    }
}
