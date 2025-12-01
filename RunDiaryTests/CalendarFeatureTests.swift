//
//  CalendarFeatureTests.swift
//  RunDiaryTests
//
//  Created by Claude on 12/1/25.
//

import ComposableArchitecture
import Foundation
import Models
import Testing

@testable import RunDiary

@MainActor
struct CalendarFeatureTests {
    // MARK: - Test Cases

    @Test("onAppear 시 초기 날짜 범위로 fetchRecords 호출")
    func onAppear_fetchRecords() async {
        // Given
        let selectedDate = YearMonthDay(year: 2025, month: 6, day: 15)
        let store = makeTestStore(selectedDate: selectedDate)

        // When
        await store.send(.onAppear)

        // Then
        await store.receive(\.fetchRecords) {
            $0.isLoading = true
        }
        await store.receive(\.recordsFetched) {
            $0.isLoading = false
        }
        await store.receive(\.delegate)
    }

    @Test("fetchRecords 성공 시 dailyRecords 및 monthlyTotals 업데이트")
    func fetchRecords_success() async {
        // Given
        let startDate = YearMonthDay(year: 2025, month: 6, day: 1)
        let endDate = YearMonthDay(year: 2025, month: 6, day: 30)

        let mockRecord = makeRunningRecord(yearMonthDay: startDate)

        let expectedDailyRecords: [YearMonthDay: DailyRecord] = [
            startDate: DailyRecord(
                yearMonthDay: startDate,
                healthKitWorkouts: [],
                savedRecords: [mockRecord]
            )
        ]

        let store = makeTestStore(
            selectedDate: startDate,
            mockDailyRecords: expectedDailyRecords
        )

        // When
        await store.send(.fetchRecords(startDate: startDate, endDate: endDate)) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.recordsFetched) {
            $0.isLoading = false
            $0.dailyRecords = expectedDailyRecords
            let yearMonth = startDate.toYearMonth()
            $0.monthlyTotals[yearMonth] = 5.0
        }

        await store.receive(\.delegate)
    }

    @Test("fetchRecords 실패 시 에러 처리")
    func fetchRecords_failure() async {
        // Given
        let startDate = YearMonthDay(year: 2025, month: 6, day: 1)
        let endDate = YearMonthDay(year: 2025, month: 6, day: 30)

        let store = makeTestStore(
            selectedDate: startDate,
            shouldFail: true
        )

        // When
        await store.send(.fetchRecords(startDate: startDate, endDate: endDate)) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.recordsFetchedFailure) {
            $0.isLoading = false
        }
    }

    @Test("잘못된 날짜 범위로 fetchRecords 호출 시 즉시 에러")
    func fetchRecords_invalidDateRange() async {
        // Given
        let startDate = YearMonthDay(year: 2025, month: 6, day: 30)
        let endDate = YearMonthDay(year: 2025, month: 6, day: 1)
        let store = makeTestStore(selectedDate: startDate)

        // When & Then
        await store.send(.fetchRecords(startDate: startDate, endDate: endDate))
        await store.receive(\.recordsFetchedFailure)
    }

    @Test("fetchOlderRecords 시 startDate 확장 및 추가 fetch")
    func fetchOlderRecords_extendsStartDate() async {
        // Given
        let selectedDate = YearMonthDay(year: 2025, month: 6, day: 15)
        let store = makeTestStore(selectedDate: selectedDate)
        let originalStartDate = store.state.startDate

        // When
        await store.send(.fetchOlderRecords) {
            // startDate가 6개월 이전으로 확장
            let expectedNewStart = originalStartDate.add(month: -6)!
            $0.startDate = expectedNewStart
        }

        // Then - fetchRecords 액션과 그 결과를 모두 받아야 함
        await store.receive(\.fetchRecords) {
            $0.isLoading = true
        }
        await store.receive(\.recordsFetched) {
            $0.isLoading = false
        }
        await store.receive(\.delegate)
    }

    @Test("selectDate 시 selectedDate 업데이트")
    func selectDate_updatesSelectedDate() async {
        // Given
        let initialDate = YearMonthDay(year: 2025, month: 6, day: 15)
        let newDate = YearMonthDay(year: 2025, month: 6, day: 20)
        let store = makeTestStore(selectedDate: initialDate)

        // When & Then
        await store.send(.selectDate(newDate)) {
            $0.selectedDate = newDate
        }
    }

    // MARK: - Helper

    private func makeTestStore(
        selectedDate: YearMonthDay,
        mockDailyRecords: [YearMonthDay: DailyRecord] = [:],
        shouldFail: Bool = false
    ) -> TestStore<CalendarFeature.State, CalendarFeature.Action> {
        TestStore(
            initialState: CalendarFeature.State(selectedDate: selectedDate)
        ) {
            CalendarFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchData = { from, to in
                if shouldFail {
                    struct TestError: Error {}
                    throw TestError()
                }
                return mockDailyRecords
            }
        }
    }

    private func makeRunningRecord(
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
}
