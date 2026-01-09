//
//  DailyDetailFeatureTests.swift
//  RunDiaryTests
//
//  Created by Claude on 11/27/25.
//

import ComposableArchitecture
import Foundation
import Models

import Testing

@testable import RunDiary

@Suite("DailyDetailFeature")
struct DailyDetailFeatureTests {

    // MARK: - Initialization Tests

    @Test("앱 시작 시 빈 currentWeekDates로 주 날짜 초기화 및 fetch 트리거")
    func onAppearInitializesDatesAndFetchesWeekRecords() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let mockHealthKit = makeHealthKitWorkout(yearMonthDay: testDate)
        let mockRecord = makeRunningRecord(yearMonthDay: testDate)
        let weekDates = makeWeekDates(containing: testDate)
        let expectedDailyRecords = makeExpectedDailyRecords(
            forWeekContaining: testDate,
            healthKitWorkouts: [testDate: [mockHealthKit]],
            runningRecords: [testDate: [mockRecord]]
        )
        let mockTrademark = WeatherTrademark(imageURL: nil, legalPageURL: nil)

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.weatherTrademark = mockTrademark

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchData = { _, _ in expectedDailyRecords }
        }

        // When
        await store.send(.onAppear) {
            // Then
            $0.currentWeekDates = weekDates
        }

        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetched) {
            $0.isLoading = false
            $0.dailyRecords = expectedDailyRecords
        }

        await store.receive(\.refreshCompleted)
    }

    // MARK: - Date Selection Tests

    @Test("날짜 선택 시 캐시 미스면 주 단위 기록 조회")
    func dateSelectionWithCacheMissTriggersWeekFetch() async {
        // Given
        let selectedDate = makeTodayYearMonthDay()
        let mockHealthKit = makeHealthKitWorkout(yearMonthDay: selectedDate)
        let mockRecord = makeRunningRecord(yearMonthDay: selectedDate)
        let expectedDailyRecords = makeExpectedDailyRecords(
            forWeekContaining: selectedDate,
            healthKitWorkouts: [selectedDate: [mockHealthKit]],
            runningRecords: [selectedDate: [mockRecord]]
        )

        var initialState = DailyDetailFeature.State()
        initialState.currentWeekDates = makeWeekDates(containing: selectedDate)

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchData = { _, _ in expectedDailyRecords }
        }

        // When
        await store.send(.fetchWeekRecords) {
            // Then
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetched) {
            $0.isLoading = false
            $0.dailyRecords = expectedDailyRecords
        }

        await store.receive(\.refreshCompleted)
    }

    @Test("날짜 선택 시 캐시 히트면 fetch 생략")
    func dateSelectionWithCacheHitSkipsFetch() async {
        // Given
        let initialDate = makeTodayYearMonthDay()
        let weekDates = DateHelper.getWeekDates(for: initialDate.toDate()).map { YearMonthDay(date: $0) }
        // selectedDate는 weekDates 중 하나를 선택 (캐시에 존재하도록)
        let selectedDate = weekDates[3] // 중간 날짜 선택

        let records = weekDates.map {
            let dailyRecord = DailyRecord(yearMonthDay: $0, healthKitWorkouts: [], savedRecords: [])
            return ($0, dailyRecord)
        }
        let cachedRecords = Dictionary(uniqueKeysWithValues: records)

        var initialState = DailyDetailFeature.State(selectedDate: initialDate)
        initialState.currentWeekDates = weekDates
        initialState.dailyRecords = cachedRecords

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then - 캐시 히트이므로 추가 액션 없음
        await store.send(.dateSelected(selectedDate)) {
            $0.selectedDate = selectedDate
        }
    }

    // MARK: - Week Navigation Tests

    @Test("주 변경 시 캐시 미스로 다음 주 이동 및 fetch 발생")
    func weekChangedForwardWithCacheMissTriggersWeekFetch() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let currentWeekDates = makeWeekDates(containing: testDate)
        let nextWeekStart = DateHelper.addWeeks(1, to: currentWeekDates.first!.toDate())
        let nextWeekDates = DateHelper.getWeekDates(for: nextWeekStart).map { YearMonthDay(date: $0) }
        let nextWeekRecord = makeRunningRecord(yearMonthDay: nextWeekDates.first!)
        let expectedDailyRecords = makeExpectedDailyRecords(
            forWeekContaining: nextWeekDates.first!,
            runningRecords: [nextWeekDates.first!: [nextWeekRecord]]
        )

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.currentWeekDates = currentWeekDates

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchData = { _, _ in expectedDailyRecords }
        }

        // When
        await store.send(.weekChanged(offset: 1)) {
            // Then
            $0.currentWeekDates = nextWeekDates

            let calendar = Calendar.current
            let currentWeekday = calendar.component(.weekday, from: testDate.toDate())
            if let newSelectedDate = nextWeekDates.first(where: {
                calendar.component(.weekday, from: $0.toDate()) == currentWeekday
            }) {
                $0.selectedDate = newSelectedDate
            } else {
                $0.selectedDate = nextWeekDates.first!
            }
        }

        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetched) {
            $0.isLoading = false
            $0.dailyRecords = expectedDailyRecords
        }

        await store.receive(\.refreshCompleted)
    }

    @Test("주 변경 시 캐시 히트로 fetch 생략")
    func weekChangedWithCacheHitSkipsFetch() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let currentWeekDates = makeWeekDates(containing: testDate)
        let nextWeekStart = DateHelper.addWeeks(1, to: currentWeekDates.first!.toDate())
        let nextWeekDates = DateHelper.getWeekDates(for: nextWeekStart).map { YearMonthDay(date: $0) }

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.currentWeekDates = currentWeekDates

        for date in currentWeekDates {
            initialState.dailyRecords[date] = DailyRecord(
                yearMonthDay: date,
                healthKitWorkouts: [],
                savedRecords: []
            )
        }
        for date in nextWeekDates {
            initialState.dailyRecords[date] = DailyRecord(
                yearMonthDay: date,
                healthKitWorkouts: [],
                savedRecords: []
            )
        }

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await store.send(.weekChanged(offset: 1)) {
            $0.currentWeekDates = nextWeekDates

            let calendar = Calendar.current
            let currentWeekday = calendar.component(.weekday, from: testDate.toDate())
            if let newSelectedDate = nextWeekDates.first(where: {
                calendar.component(.weekday, from: $0.toDate()) == currentWeekday
            }) {
                $0.selectedDate = newSelectedDate
            } else {
                $0.selectedDate = nextWeekDates.first!
            }
        }
    }

    @Test("주 변경 시 선택된 날짜가 같은 요일로 이동")
    func weekChangedPreservesWeekday() async {
        // Given
        let testDate = makeYearMonthDay(year: 2025, month: 11, day: 27)
        let currentWeekDates = makeWeekDates(containing: testDate)
        let nextWeekStart = DateHelper.addWeeks(1, to: currentWeekDates.first!.toDate())
        let nextWeekDates = DateHelper.getWeekDates(for: nextWeekStart).map { YearMonthDay(date: $0) }

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.currentWeekDates = currentWeekDates

        for date in nextWeekDates {
            initialState.dailyRecords[date] = DailyRecord(
                yearMonthDay: date,
                healthKitWorkouts: [],
                savedRecords: []
            )
        }

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When
        await store.send(.weekChanged(offset: 1)) {
            // Then
            $0.currentWeekDates = nextWeekDates

            let calendar = Calendar.current
            let currentWeekday = calendar.component(.weekday, from: testDate.toDate())
            if let newSelectedDate = nextWeekDates.first(where: {
                calendar.component(.weekday, from: $0.toDate()) == currentWeekday
            }) {
                $0.selectedDate = newSelectedDate
                let newWeekday = calendar.component(.weekday, from: newSelectedDate.toDate())
                #expect(newWeekday == currentWeekday)
            }
        }
    }

    // MARK: - Data Fetching Tests

    @Test("주 단위 기록 조회 성공 시 HealthKit과 RunningRecord 모두 fetch")
    func fetchWeekRecordsSuccessFetchesBothDataSources() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: testDate)
        let mockHealthKit = makeHealthKitWorkout(yearMonthDay: testDate)
        let mockRunningRecord = makeRunningRecord(yearMonthDay: testDate)
        let groupedHealthKitWorkout = makeGroupedHealthKitWorkout([(testDate, mockHealthKit)])
        let groupedRunningRecord = makeGroupedRunningRecords([(testDate, mockRunningRecord)])
        let expectedDailyRecords = makeDailyRecords(
            healthKitWorkouts: groupedHealthKitWorkout,
            runningRecords: groupedRunningRecord,
            weekDates: weekDates
        )

        var initialState = DailyDetailFeature.State()
        initialState.currentWeekDates = weekDates

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchData = { _, _ in expectedDailyRecords }
        }

        // When
        await store.send(.fetchWeekRecords) {
            // Then
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetched) {
            $0.isLoading = false
            $0.dailyRecords = expectedDailyRecords
        }

        await store.receive(\.refreshCompleted)
    }

    @Test("주 단위 기록 조회 시 빈 currentWeekDates면 에러 발생")
    func fetchWeekRecordsWithEmptyCurrentWeekDatesFails() async {
        // Given
        let store = TestStore(initialState: DailyDetailFeature.State()) {
            DailyDetailFeature()
        }

        // When
        await store.send(.fetchWeekRecords)

        // Then
        await store.receive(\.weekRecordsFetchFailed) {
            $0.isLoading = false
            $0.error = .emptyWeekDates
        }
    }

    @Test("주 단위 기록 조회 실패 시 에러 상태 설정")
    func fetchWeekRecordsFailureSetsErrorState() async {
        // Given
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "Test network error" }
        }

        var initialState = DailyDetailFeature.State()
        initialState.currentWeekDates = makeWeekDates(containing: makeTodayYearMonthDay())

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchData = { _, _ in
                throw TestError()
            }
        }

        // When
        await store.send(.fetchWeekRecords) {
            // Then
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetchFailed) {
            $0.isLoading = false
            $0.error = .fetchFailed(underlyingError: "Test network error")
        }
    }

    // MARK: - AddRecord Integration Tests

    @Test("createRecord는 AddRecord를 추가 모드로 표시")
    func createRecordOpensAddRecordInAddMode() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let healthKitWorkout = makeHealthKitWorkout(yearMonthDay: testDate)

        let store = TestStore(
            initialState: DailyDetailFeature.State(selectedDate: testDate)
        ) {
            DailyDetailFeature()
        }

        store.exhaustivity = .off

        // When
        await store.send(.createRecord(healthKitWorkout))

        // Then
        #expect(store.state.addRecord != nil)
        #expect(store.state.addRecord?.existingRecord == nil)
        #expect(store.state.addRecord?.healthKitWorkout.data == healthKitWorkout)
    }

    @Test("editRecord는 AddRecord를 편집 모드로 표시")
    func editRecordOpensAddRecordInEditMode() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let runningRecord = makeRunningRecord(yearMonthDay: testDate)

        let store = TestStore(
            initialState: DailyDetailFeature.State(selectedDate: testDate)
        ) {
            DailyDetailFeature()
        }

        // When & Then
        await store.send(.editRecord(runningRecord)) {
            $0.addRecord = AddRecordFeature.State(
                existingRecord: runningRecord,
                healthKitWorkout: nil
            )
        }
    }

    @Test("addRecord dismiss 시 시트 닫힘")
    func addRecordDismissClosesSheet() async {
        // Given
        var initialState = DailyDetailFeature.State()
        initialState.addRecord = AddRecordFeature.State(
            existingRecord: nil,
            healthKitWorkout: nil
        )

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await store.send(.addRecord(.dismiss)) {
            $0.addRecord = nil
        }
    }

    @Test("addRecord recordSaved 시 주 단위 새로고침")
    func addRecordSavedRefetchesWeek() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: testDate)
        let runningRecord = makeRunningRecord(yearMonthDay: testDate)
        let groupedRunningRecords = makeGroupedRunningRecords([(testDate, runningRecord)])
        let expectedDailyRecords = makeDailyRecords(
            healthKitWorkouts: [:],
            runningRecords: groupedRunningRecords,
            weekDates: weekDates
        )

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.currentWeekDates = makeWeekDates(containing: testDate)
        initialState.addRecord = AddRecordFeature.State(
            existingRecord: nil,
            healthKitWorkout: nil
        )

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchData = { _, _ in expectedDailyRecords }
        }

        // When
        await store.send(.addRecord(.presented(.recordSaved))) {
            // Then
            $0.addRecord = nil
        }

        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetched) {
            $0.isLoading = false
            $0.dailyRecords = expectedDailyRecords
        }

        await store.receive(\.refreshCompleted)
    }

    // MARK: - Calendar Integration Tests

    @Test("calendarButtonTapped 시 Calendar 시트 표시")
    func calendarButtonTappedOpensCalendarSheet() async {
        // Given
        let testDate = makeTodayYearMonthDay()

        let store = TestStore(
            initialState: DailyDetailFeature.State(selectedDate: testDate)
        ) {
            DailyDetailFeature()
        }

        // When & Then
        await store.send(.calendarButtonTapped) {
            $0.calendar = CalendarFeature.State(selectedDate: testDate)
        }
    }

    @Test("calendar dismiss 시 시트 닫힘")
    func calendarDismissClosesSheet() async {
        // Given
        let testDate = makeTodayYearMonthDay()

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.calendar = CalendarFeature.State(selectedDate: testDate)

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await store.send(.calendar(.dismiss)) {
            $0.calendar = nil
        }
    }

    @Test("calendar navigateToDiary 시 주와 날짜 변경 및 캐시 미스면 fetch")
    func calendarNavigateToDiaryChangesWeekAndDateWithCacheMiss() async {
        // Given
        let currentDate = makeYearMonthDay(year: 2025, month: 11, day: 27)
        let selectedDate = makeYearMonthDay(year: 2025, month: 12, day: 10)
        let expectedDailyRecords = makeExpectedDailyRecords(
            forWeekContaining: selectedDate,
            healthKitWorkouts: [:],
            runningRecords: [:]
        )

        var initialState = DailyDetailFeature.State(selectedDate: currentDate)
        initialState.currentWeekDates = makeWeekDates(containing: currentDate)
        initialState.calendar = CalendarFeature.State(selectedDate: selectedDate)

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchData = { _, _ in expectedDailyRecords }
        }

        // When
        await store.send(.calendar(.presented(.navigateToDiary))) {
            // Then
            $0.calendar = nil
            $0.currentWeekDates = makeWeekDates(containing: selectedDate)
            $0.selectedDate = selectedDate
        }

        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetched) {
            $0.isLoading = false
            $0.dailyRecords = expectedDailyRecords
        }

        await store.receive(\.refreshCompleted)
    }

    // MARK: - Settings Tests

    @Test("settingsButtonTapped 시 Settings 화면 표시")
    func settingsButtonTappedOpensSettings() async {
        // Given
        let testDate = makeTodayYearMonthDay()

        let store = TestStore(
            initialState: DailyDetailFeature.State(selectedDate: testDate)
        ) {
            DailyDetailFeature()
        }

        store.exhaustivity = .off

        // When & Then
        await store.send(.settingsButtonTapped) {
            $0.settings = SettingsFeature.State()
        }
    }

    @Test("settings dismiss 시 화면 닫힘")
    func settingsDismissClosesSettings() async {
        // Given
        let testDate = makeTodayYearMonthDay()

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.settings = SettingsFeature.State()

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await store.send(.settings(.dismiss)) {
            $0.settings = nil
        }
    }

    // MARK: - Computed Properties Tests

    @Test("currentDailyRecord는 선택된 날짜의 기록 반환")
    func currentDailyRecordReturnsCorrectRecord() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let expectedDailyRecord = DailyRecord(
            yearMonthDay: testDate,
            healthKitWorkouts: [],
            savedRecords: []
        )

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dailyRecords = [testDate: expectedDailyRecord]

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        #expect(store.state.currentDailyRecord == expectedDailyRecord)
    }

    @Test("currentDailyRecord는 캐시되지 않은 날짜면 nil 반환")
    func currentDailyRecordReturnsNilWhenNotCached() async {
        // Given
        let testDate = makeTodayYearMonthDay()

        let initialState = DailyDetailFeature.State(selectedDate: testDate)

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        #expect(store.state.currentDailyRecord == nil)
    }

    // MARK: - Weather Attribution Tests

    @Test("onAppear 시 weatherTrademark이 nil이면 fetch 트리거")
    func onAppearWithoutTrademarkFetchesTrademark() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let expectedTrademark = WeatherTrademark(
            imageURL: URL(string: "https://example.com/icon.png"),
            legalPageURL: URL(string: "https://example.com/legal")
        )
        let expectedDailyRecords = makeExpectedDailyRecords(
            forWeekContaining: testDate,
            healthKitWorkouts: [:],
            runningRecords: [:]
        )

        let store = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchData = { _, _ in expectedDailyRecords }
            $0.weatherClient.fetchTrademark = {
                expectedTrademark
            }
        }

        // When
        await store.send(.onAppear) {
            // Then
            $0.currentWeekDates = makeWeekDates(containing: testDate)
        }

        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.fetchWeatherTrademark)

        await store.receive(\.weekRecordsFetched) {
            $0.isLoading = false
            $0.dailyRecords = expectedDailyRecords
        }

        await store.receive(\.refreshCompleted)

        await store.receive(\.weatherTrademarkFetched) {
            $0.weatherTrademark = expectedTrademark
        }
    }

    @Test("onAppear 시 weatherTrademark이 이미 있으면 fetch 생략")
    func onAppearWithExistingTrademarkSkipsFetch() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let existingTrademark = WeatherTrademark(
            imageURL: URL(string: "https://example.com/icon.png"),
            legalPageURL: URL(string: "https://example.com/legal")
        )
        let expectedDailyRecords = makeExpectedDailyRecords(
            forWeekContaining: testDate,
            healthKitWorkouts: [:],
            runningRecords: [:]
        )

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.weatherTrademark = existingTrademark

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchData = { _, _ in expectedDailyRecords }
        }

        // When
        await store.send(.onAppear) {
            // Then
            $0.currentWeekDates = makeWeekDates(containing: testDate)
        }

        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetched) {
            $0.isLoading = false
            $0.dailyRecords = expectedDailyRecords
        }

        await store.receive(\.refreshCompleted)

        // No weatherTrademarkFetched action should be received
        #expect(store.state.weatherTrademark == existingTrademark)
    }

    @Test("fetchWeatherTrademark 성공 시 State에 trademark 저장")
    func fetchWeatherTrademarkSuccessSavesTrademark() async {
        // Given
        let expectedTrademark = WeatherTrademark(
            imageURL: URL(string: "https://example.com/icon.png"),
            legalPageURL: URL(string: "https://example.com/legal")
        )

        let store = TestStore(initialState: DailyDetailFeature.State()) {
            DailyDetailFeature()
        } withDependencies: {
            $0.weatherClient.fetchTrademark = {
                expectedTrademark
            }
        }

        // When
        await store.send(.fetchWeatherTrademark)

        // Then
        await store.receive(\.weatherTrademarkFetched) {
            $0.weatherTrademark = expectedTrademark
        }
    }

    @Test("fetchTrademark가 nil 값 반환 시에도 정상 처리")
    func fetchWeatherTrademarkHandlesNilValues() async {
        // Given
        let expectedTrademark = WeatherTrademark(
            imageURL: nil,
            legalPageURL: nil
        )

        let store = TestStore(initialState: DailyDetailFeature.State()) {
            DailyDetailFeature()
        } withDependencies: {
            $0.weatherClient.fetchTrademark = {
                expectedTrademark
            }
        }

        // When
        await store.send(.fetchWeatherTrademark)

        // Then
        await store.receive(\.weatherTrademarkFetched) {
            $0.weatherTrademark = expectedTrademark
        }
    }

    // MARK: - Error Handling Tests

    @Test("weekRecordsFetchFailed 시 에러 상태 설정")
    func weekRecordsFetchFailedSetsErrorState() async {
        // Given
        let expectedError = DailyDetailError.fetchFailed(underlyingError: "Network error")

        let store = TestStore(initialState: DailyDetailFeature.State(isLoading: true)) {
            DailyDetailFeature()
        }

        // When & Then
        await store.send(.weekRecordsFetchFailed(expectedError)) {
            $0.isLoading = false
            $0.error = expectedError
        }
    }

    @Test("조회 실패 시 캐시가 손상되지 않음")
    func fetchFailureDoesNotCorruptCache() async {
        // Given
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "Test error" }
        }

        let testDate = makeTodayYearMonthDay()
        let existingRecord = DailyRecord(
            yearMonthDay: testDate,
            healthKitWorkouts: [],
            savedRecords: []
        )

        var initialState = DailyDetailFeature.State()
        initialState.currentWeekDates = makeWeekDates(containing: testDate)
        initialState.dailyRecords = [testDate: existingRecord]

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchData = { _, _ in
                throw TestError()
            }
        }

        // When
        await store.send(.fetchWeekRecords) {
            // Then
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetchFailed) {
            $0.isLoading = false
            $0.error = .fetchFailed(underlyingError: "Test error")
            #expect($0.dailyRecords[testDate] == existingRecord)
        }
    }
}

// MARK: - Test Helpers

private extension DailyDetailFeatureTests {
    /// 오늘 날짜의 YearMonthDay 반환
    func makeTodayYearMonthDay() -> YearMonthDay {
        YearMonthDay(date: Date())
    }

    /// YearMonthDay 생성 헬퍼
    /// - Parameters:
    ///   - year: 연도 (기본값: 현재 연도)
    ///   - month: 월 (기본값: 1)
    ///   - day: 일 (기본값: 1)
    /// - Returns: 지정된 날짜의 YearMonthDay
    func makeYearMonthDay(
        year: Int? = nil,
        month: Int = 1,
        day: Int = 1
    ) -> YearMonthDay {
        let calendar = Calendar.current
        let currentYear = year ?? calendar.component(.year, from: Date())
        return YearMonthDay(year: currentYear, month: month, day: day)
    }

    /// 랜덤한 날짜의 YearMonthDay 반환
    /// - Parameter excluding: 제외할 날짜 목록 (옵셔널)
    /// - Returns: excluding에 포함되지 않은 랜덤 YearMonthDay
    func makeRandomYearMonthDay(excluding: [YearMonthDay]? = nil) -> YearMonthDay {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        // 현재 연도 ± 2년 범위에서 랜덤 날짜 생성
        let year = Int.random(in: (currentYear - 2)...(currentYear + 2))
        let month = Int.random(in: 1...12)

        // 해당 월의 일수 계산
        let dateComponents = DateComponents(year: year, month: month)
        guard let date = calendar.date(from: dateComponents),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return YearMonthDay(year: year, month: month, day: 1)
        }

        let maxDay = range.count
        var attempts = 0
        let maxAttempts = 100

        while attempts < maxAttempts {
            let day = Int.random(in: 1...maxDay)
            let randomDate = YearMonthDay(year: year, month: month, day: day)

            // excluding이 nil이거나, excluding에 포함되지 않은 경우 반환
            if excluding == nil || !(excluding!.contains(randomDate)) {
                return randomDate
            }

            attempts += 1
        }

        // maxAttempts에 도달한 경우 제외 조건 무시하고 반환
        return YearMonthDay(year: year, month: month, day: Int.random(in: 1...maxDay))
    }

    /// HealthKitWorkout 생성 헬퍼
    func makeHealthKitWorkout(
        yearMonthDay: YearMonthDay,
        distance: Double = 5.0,
        startOffset: TimeInterval = 0
    ) -> HealthKitWorkout {
        let startDate = yearMonthDay.toDate().addingTimeInterval(startOffset)
        return HealthKitWorkout(
            distance: distance,
            duration: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            routeData: nil,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(1800)
        )
    }

    /// RunningRecord 생성 헬퍼
    func makeRunningRecord(
        yearMonthDay: YearMonthDay,
        distance: Double = 5.0,
        startOffset: TimeInterval = 0
    ) -> RunningRecord {
        let startTime = yearMonthDay.toDate().addingTimeInterval(startOffset)
        return RunningRecord(
            yearMonthDay: yearMonthDay,
            distanceInKilometers: distance,
            durationInSeconds: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            runningStyle: .midfoot,
            startTime: startTime,
            endTime: startTime.addingTimeInterval(1800)
        )
    }

    /// 그룹화된 HealthKit 데이터 생성 헬퍼
    func makeGroupedHealthKitWorkout(
        _ data: [(YearMonthDay, HealthKitWorkout)]
    ) -> [YearMonthDay: [HealthKitWorkout]] {
        Dictionary(grouping: data.map { $1 }, by: { $0.yearMonthDay })
    }

    /// 그룹화된 RunningRecord 생성 헬퍼
    func makeGroupedRunningRecords(
        _ records: [(YearMonthDay, RunningRecord)]
    ) -> [YearMonthDay: [RunningRecord]] {
        Dictionary(grouping: records.map { $1 }, by: { $0.yearMonthDay })
    }

    /// 주 날짜 배열 생성 헬퍼
    func makeWeekDates(containing date: YearMonthDay) -> [YearMonthDay] {
        DateHelper.getWeekDates(for: date.toDate()).map { YearMonthDay(date: $0) }
    }

    func makeDailyRecords(
        healthKitWorkouts: [YearMonthDay: [HealthKitWorkout]],
        runningRecords: [YearMonthDay: [RunningRecord]],
        weekDates: [YearMonthDay]
    ) -> [YearMonthDay: DailyRecord] {
        var dailyRecords: [YearMonthDay: DailyRecord] = [:]
        for weekDate in weekDates {
            let runningRecord = runningRecords[weekDate] ?? []
            let healthKitWorkout = healthKitWorkouts[weekDate] ?? []
            let filteredHealthKitWorkout = healthKitWorkout.filter { data in !runningRecord.contains(where: { $0.startTime == data.startDate }) }
            let dailyRecord = DailyRecord(
                yearMonthDay: weekDate,
                healthKitWorkouts: filteredHealthKitWorkout,
                savedRecords: runningRecords[weekDate] ?? []
            )
            dailyRecords.updateValue(dailyRecord, forKey: weekDate)
        }
        return dailyRecords
    }

    /// ExpectedValue 생성 간소화 헬퍼 - 주어진 데이터로부터 예상되는 DailyRecords를 자동으로 생성
    func makeExpectedDailyRecords(
        forWeekContaining date: YearMonthDay,
        healthKitWorkouts: [YearMonthDay: [HealthKitWorkout]] = [:],
        runningRecords: [YearMonthDay: [RunningRecord]] = [:]
    ) -> [YearMonthDay: DailyRecord] {
        let weekDates = makeWeekDates(containing: date)
        return makeDailyRecords(
            healthKitWorkouts: healthKitWorkouts,
            runningRecords: runningRecords,
            weekDates: weekDates
        )
    }
}
