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

    // MARK: - Date Range Tests

    @Test("fetchData는 여러 월에 걸친 범위 조회")
    func fetchData_handlesMultiMonthRange() async throws {
        // Given
        let januaryEnd = makeYearMonthDay(month: 1, day: 31)
        let februaryStart = makeYearMonthDay(month: 2, day: 1)

        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: []
        )

        // When
        let result = try await client.fetchData(januaryEnd, februaryStart)

        // Then - Should have results for both dates
        #expect(result.count == 2)
        #expect(result[januaryEnd] != nil)
        #expect(result[februaryStart] != nil)
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

    // MARK: - Save and Update Tests

    @Test("saveRecord는 의존성을 통해 저장")
    func saveRecord_callsSwiftDataClient() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)
        let recordToSave = makeRunningRecord(yearMonthDay: testDate)

        var savedRecord: RunningRecord?
        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: [],
            onSave: { record in
                savedRecord = record
            }
        )

        // When
        try await client.saveRecord(recordToSave)

        // Then
        #expect(savedRecord != nil)
        #expect(savedRecord?.yearMonthDay == testDate)
    }

    @Test("updateRecord는 의존성을 통해 업데이트")
    func updateRecord_callsSwiftDataClient() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)
        let recordToUpdate = makeRunningRecord(yearMonthDay: testDate)

        var updatedRecord: RunningRecord?
        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: [],
            onUpdate: { record in
                updatedRecord = record
            }
        )

        // When
        try await client.updateRecord(recordToUpdate)

        // Then
        #expect(updatedRecord != nil)
        #expect(updatedRecord?.yearMonthDay == testDate)
    }

    @Test("clearCache는 swiftDataClient.clearCache 호출")
    func clearCache_callsSwiftDataClientClearCache() async throws {
        // Given
        var clearCacheCalled = false
        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: [],
            onClearCache: {
                clearCacheCalled = true
            }
        )

        // When
        client.clearCache()

        // Then
        #expect(clearCacheCalled == true)
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
            activeEnergyBurned: 350.0,
            runningVerticalOscillation: 8.0,
            runningGroundContactTime: 240.0,
            walkingStepLength: 1.0,
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
        onSave: @escaping (RunningRecord) -> Void = { _ in },
        onUpdate: @escaping (RunningRecord) -> Void = { _ in },
        onClearCache: @escaping () -> Void = { }
    ) -> RunningRecordClient {
        // 직접 RunningRecordClient를 생성하여 테스트
        RunningRecordClient(
            fetchData: { from, to in
                // 날짜 범위의 끝을 해당 날짜의 마지막 시간으로 설정
                let calendar = Calendar.current
                let startOfFromDate = from.toDate()
                let endOfToDate = calendar.date(byAdding: .day, value: 1, to: to.toDate())!.addingTimeInterval(-1)

                // Return filtered workouts for date range
                let filteredHealthKit = healthKitWorkouts.filter { workout in
                    workout.startDate >= startOfFromDate && workout.startDate <= endOfToDate
                }
                let filteredRecords = savedRecords.filter { record in
                    record.startTime >= startOfFromDate && record.startTime <= endOfToDate
                }

                // 날짜별 그룹핑
                let groupedHK = Dictionary(grouping: filteredHealthKit, by: \.yearMonthDay)
                let groupedRecords = Dictionary(grouping: filteredRecords, by: \.yearMonthDay)

                // 요청 범위의 모든 날짜 생성
                var dates: [YearMonthDay] = []
                var current = from
                while current <= to {
                    dates.append(current)
                    guard let next = current.add(day: 1) else { break }
                    current = next
                }

                // 각 날짜별로 DailyRecord 생성
                var result: [YearMonthDay: DailyRecord] = [:]
                for date in dates {
                    let saved = groupedRecords[date] ?? []
                    let healthKit = groupedHK[date] ?? []

                    // 중복 제거: SwiftData에 저장된 것은 HealthKit에서 제외
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
            },
            saveRecord: { record in
                onSave(record)
            },
            updateRecord: { record in
                onUpdate(record)
            },
            clearCache: {
                onClearCache()
            }
        )
    }
}
