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

@Suite("DailyDetail Feature")
struct DailyDetailFeatureTests {
    // MARK: - Initialization Tests

    @Test("앱 시작 시 빈 currentWeekDates로 주 날짜 초기화 및 fetch 트리거")
    func onAppearInitializesDatesAndFetchesWeekRecords() async {
        let testDate = makeTodayYearMonthDay()
        let mockHealthKit = makeHealthKitData(yearMonthDay: testDate)
        let mockRecord = makeRunningRecord(yearMonthDay: testDate)
        let weekDates = makeWeekDates(containing: testDate)

        let expectedValue = makeExpectedDailyRecords(
            forWeekContaining: testDate,
            healthKitDatas: [testDate: [mockHealthKit]],
            runningRecords: [testDate: [mockRecord]]
        )

        let store = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchRecords = { _, _ in [mockRecord] }
            $0.healthKitClient.ensureAuthorizationIfNeeded = {}
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in [mockHealthKit] }
        }

        await store.send(.onAppear) {
            $0.currentWeekDates = weekDates
        }

        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.healthKitDatasFetched) {
            $0.healthKitDatas[testDate] = [mockHealthKit]
        }

        await store.receive(\.runningRecordsFetched) {
            $0.runningRecords[testDate] = [mockRecord]
        }

        await store.receive(\.mergeDailyRecords) {
            $0.isLoading = false
            $0.dailyRecords = expectedValue
        }
    }

    // MARK: - Date Selection Tests

    @Test("날짜 선택 시 캐시 미스면 주 단위 기록 조회")
    func dateSelectionWithCacheMissTriggersWeekFetch() async {
        let selectedDate = makeTodayYearMonthDay()
        let mockHealthKit = makeHealthKitData(yearMonthDay: selectedDate)
        let mockRecord = makeRunningRecord(yearMonthDay: selectedDate)

        let expectedValue = makeExpectedDailyRecords(
            forWeekContaining: selectedDate,
            healthKitDatas: [selectedDate: [mockHealthKit]],
            runningRecords: [selectedDate: [mockRecord]]
        )

        var initialState = DailyDetailFeature.State()
        initialState.currentWeekDates = makeWeekDates(containing: selectedDate)

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchRecords = { _, _ in [mockRecord] }
            $0.healthKitClient.ensureAuthorizationIfNeeded = {}
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in [mockHealthKit] }
        }

        await store.send(.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.healthKitDatasFetched) {
            $0.healthKitDatas = [selectedDate: [mockHealthKit]]
        }

        await store.receive(\.runningRecordsFetched) {
            $0.runningRecords = [selectedDate: [mockRecord]]
        }

        await store.receive(\.mergeDailyRecords) {
            $0.isLoading = false
            $0.dailyRecords = expectedValue
        }
    }

    @Test("날짜 선택 시 캐시 히트면 fetch 생략")
    func dateSelectionWithCacheHitSkipsFetch() async {
        let initialDate = makeTodayYearMonthDay()
        let selectedDate = initialDate.add(day: -1)!
        let weekDates = DateHelper.getWeekDates(for: initialDate.toDate()).map { YearMonthDay(date: $0) }

        // 캐시 준비: weekDates의 모든 날짜에 대한 DailyRecord 생성
        let records = weekDates.map {
            let dailyRecord = DailyRecord(yearMonthDay: $0, healthKitDatas: [], savedRecords: [])
            return ($0, dailyRecord)
        }
        let cachedRecords = Dictionary(uniqueKeysWithValues: records)

        // initialState에 currentWeekDates와 캐시된 dailyRecords 설정
        var initialState = DailyDetailFeature.State(selectedDate: initialDate)
        initialState.currentWeekDates = weekDates
        initialState.dailyRecords = cachedRecords

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // 캐시에 이미 있으므로 fetch가 발생하지 않음
        await store.send(.dateSelected(selectedDate)) {
            $0.selectedDate = selectedDate
        }
    }

    // MARK: - Week Navigation Tests

    @Test("주 변경 시 캐시 미스로 다음 주 이동 및 fetch 발생")
    func weekChangedForwardWithCacheMissTriggersWeekFetch() async {
        let testDate = makeTodayYearMonthDay()
        let currentWeekDates = makeWeekDates(containing: testDate)

        let nextWeekStart = DateHelper.addWeeks(1, to: currentWeekDates.first!.toDate())
        let nextWeekDates = DateHelper.getWeekDates(for: nextWeekStart).map { YearMonthDay(date: $0) }
        let nextWeekRecord = makeRunningRecord(yearMonthDay: nextWeekDates.first!)

        // fetch 후 기대되는 dailyRecords 정의
        let expectedValue = makeExpectedDailyRecords(
            forWeekContaining: nextWeekDates.first!,
            runningRecords: [nextWeekDates.first!: [nextWeekRecord]]
        )

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.currentWeekDates = currentWeekDates

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchRecords = { _, _ in [nextWeekRecord] }
            $0.healthKitClient.ensureAuthorizationIfNeeded = {}
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in [] }
        }

        await store.send(.weekChanged(offset: 1)) {
            $0.currentWeekDates = nextWeekDates

            // selectedDate가 같은 요일로 이동
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

        // 캐시 미스로 fetch 발생
        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.healthKitDatasFetched)

        await store.receive(\.runningRecordsFetched) {
            let firstDate = nextWeekDates.first!
            $0.runningRecords[firstDate] = [nextWeekRecord]
        }

        await store.receive(\.mergeDailyRecords) {
            $0.isLoading = false
            $0.dailyRecords = expectedValue
        }
    }

    @Test("주 변경 시 캐시 히트로 fetch 생략")
    func weekChangedWithCacheHitSkipsFetch() async {
        let testDate = makeTodayYearMonthDay()
        let currentWeekDates = makeWeekDates(containing: testDate)

        let nextWeekStart = DateHelper.addWeeks(1, to: currentWeekDates.first!.toDate())
        let nextWeekDates = DateHelper.getWeekDates(for: nextWeekStart).map { YearMonthDay(date: $0) }

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.currentWeekDates = currentWeekDates

        // 현재 주와 다음 주 모두 캐싱
        for date in currentWeekDates {
            initialState.dailyRecords[date] = DailyRecord(
                yearMonthDay: date,
                healthKitDatas: [],
                savedRecords: []
            )
        }
        for date in nextWeekDates {
            initialState.dailyRecords[date] = DailyRecord(
                yearMonthDay: date,
                healthKitDatas: [],
                savedRecords: []
            )
        }

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // 다음 주로 이동
        await store.send(.weekChanged(offset: 1)) {
            $0.currentWeekDates = nextWeekDates

            // selectedDate가 같은 요일로 이동
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

        // 캐시 히트로 fetch가 발생하지 않음
    }

    @Test("주 변경 시 선택된 날짜가 같은 요일로 이동")
    func weekChangedPreservesWeekday() async {
        let testDate = makeYearMonthDay(year: 2025, month: 11, day: 27) // 목요일
        let currentWeekDates = makeWeekDates(containing: testDate)

        let nextWeekStart = DateHelper.addWeeks(1, to: currentWeekDates.first!.toDate())
        let nextWeekDates = DateHelper.getWeekDates(for: nextWeekStart).map { YearMonthDay(date: $0) }

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.currentWeekDates = currentWeekDates

        // 다음 주 캐싱
        for date in nextWeekDates {
            initialState.dailyRecords[date] = DailyRecord(
                yearMonthDay: date,
                healthKitDatas: [],
                savedRecords: []
            )
        }

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        await store.send(.weekChanged(offset: 1)) {
            $0.currentWeekDates = nextWeekDates

            // 같은 요일(목요일)로 이동 확인
            let calendar = Calendar.current
            let currentWeekday = calendar.component(.weekday, from: testDate.toDate())
            if let newSelectedDate = nextWeekDates.first(where: {
                calendar.component(.weekday, from: $0.toDate()) == currentWeekday
            }) {
                $0.selectedDate = newSelectedDate
                // 새 선택 날짜도 목요일인지 확인
                let newWeekday = calendar.component(.weekday, from: newSelectedDate.toDate())
                #expect(newWeekday == currentWeekday)
            }
        }
    }

    // MARK: - Data Fetching Tests

    @Test("주 단위 기록 조회 성공 시 HealthKit과 RunningRecord 모두 fetch")
    func fetchWeekRecordsSuccessFetchesBothDataSources() async {
        let testDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: testDate)
        let mockHealthKit = makeHealthKitData(yearMonthDay: testDate)
        let mockRunningRecord = makeRunningRecord(yearMonthDay: testDate)
        let groupedHealthKitData = makeGroupedHealthKitData([(testDate, mockHealthKit)])
        let groupedRunningRecord = makeGroupedRunningRecords([(testDate, mockRunningRecord)])
        let dailyRecords = makeDailyRecords(healthKitDatas: groupedHealthKitData, runningRecords: groupedRunningRecord, weekDates: weekDates)

        var initialState = DailyDetailFeature.State()
        initialState.currentWeekDates = weekDates

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchRecords = { _, _ in [mockRunningRecord] }
            $0.healthKitClient.ensureAuthorizationIfNeeded = {}
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in [mockHealthKit] }
        }

        await store.send(.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.healthKitDatasFetched) {
            $0.healthKitDatas[testDate] = [mockHealthKit]
        }

        await store.receive(\.runningRecordsFetched) {
            $0.runningRecords[testDate] = [mockRunningRecord]
        }

        await store.receive(\.mergeDailyRecords) {
            $0.isLoading = false
            $0.dailyRecords = dailyRecords
        }
    }

    @Test("주 단위 기록 조회 시 빈 currentWeekDates면 에러 발생")
    func fetchWeekRecordsWithEmptyCurrentWeekDatesFails() async {
        let store = TestStore(initialState: DailyDetailFeature.State()) {
            DailyDetailFeature()
        }

        await store.send(.fetchWeekRecords)

        await store.receive(\.weekRecordsFetchFailed) {
            $0.isLoading = false
            $0.error = .emptyWeekDates
        }
    }

    @Test("주 단위 기록 조회 실패 시 에러 상태 설정")
    func fetchWeekRecordsFailureSetsErrorState() async {
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "Test network error" }
        }

        var initialState = DailyDetailFeature.State()
        initialState.currentWeekDates = makeWeekDates(containing: makeTodayYearMonthDay())

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchRecords = { _, _ in
                throw TestError()
            }
            $0.healthKitClient.ensureAuthorizationIfNeeded = {}
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in [] }
        }

        await store.send(.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetchFailed) {
            $0.isLoading = false
            $0.error = .fetchFailed(underlyingError: "Test network error")
        }
    }

    // MARK: - Data Merging Tests

    @Test("mergeDailyRecords는 currentWeekDates의 모든 날짜에 대해 DailyRecord 생성")
    func mergeDailyRecordsCreatesRecordsForAllCurrentWeekDates() async {
        let testDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: testDate)

        // 7일 중 2개만 데이터가 있는 경우
        let firstDate = weekDates.first!
        let lastDate = weekDates.last!

        let healthKitData = makeHealthKitData(yearMonthDay: firstDate)
        let runningRecord = makeRunningRecord(yearMonthDay: lastDate)

        var initialState = DailyDetailFeature.State()
        initialState.currentWeekDates = weekDates
        initialState.healthKitDatas = [firstDate: [healthKitData]]
        initialState.runningRecords = [lastDate: [runningRecord]]
        initialState.isLoading = true

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        store.exhaustivity = .off

        await store.send(.mergeDailyRecords(
            healthKitDatas: initialState.healthKitDatas,
            runningRecords: initialState.runningRecords
        ))

        // 검증
        #expect(store.state.isLoading == false)
        #expect(store.state.dailyRecords.count == 7)

        for date in weekDates {
            let dailyRecord = store.state.dailyRecords[date]
            #expect(dailyRecord != nil)

            if date == firstDate {
                #expect(dailyRecord?.healthKitDatas.count == 1)
                #expect(dailyRecord?.savedRecords.isEmpty == true)
            } else if date == lastDate {
                #expect(dailyRecord?.healthKitDatas.isEmpty == true)
                #expect(dailyRecord?.savedRecords.count == 1)
            } else {
                #expect(dailyRecord?.healthKitDatas.isEmpty == true)
                #expect(dailyRecord?.savedRecords.isEmpty == true)
            }
        }
    }

    @Test("mergeDailyRecords는 중복된 HealthKit 데이터 필터링")
    func mergeDailyRecordsFiltersDuplicateHealthKitData() async {
        let testDate = makeTodayYearMonthDay()
        let startTime = testDate.toDate().addingTimeInterval(3600) // 1시간 후

        // 같은 startTime을 가진 HealthKit 데이터와 RunningRecord
        let healthKitData = makeHealthKitData(yearMonthDay: testDate, startOffset: 3600)
        let runningRecord = makeRunningRecord(yearMonthDay: testDate, startOffset: 3600)

        var initialState = DailyDetailFeature.State()
        initialState.currentWeekDates = makeWeekDates(containing: testDate)
        initialState.healthKitDatas = [testDate: [healthKitData]]
        initialState.runningRecords = [testDate: [runningRecord]]

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        store.exhaustivity = .off

        await store.send(.mergeDailyRecords(
            healthKitDatas: initialState.healthKitDatas,
            runningRecords: initialState.runningRecords
        ))

        // 검증
        #expect(store.state.isLoading == false)

        let dailyRecord = store.state.dailyRecords[testDate]
        #expect(dailyRecord != nil)

        // HealthKit 데이터는 중복으로 제거되어야 함
        #expect(dailyRecord?.healthKitDatas.isEmpty == true)
        // RunningRecord는 남아있어야 함
        #expect(dailyRecord?.savedRecords.count == 1)
    }

    @Test("mergeDailyRecords는 HealthKit 데이터를 startDate 순으로 정렬")
    func mergeDailyRecordsSortsHealthKitDataByStartDate() async {
        let testDate = makeTodayYearMonthDay()

        // 3개의 HealthKit 데이터를 다른 시간대로 생성
        let healthKit1 = makeHealthKitData(yearMonthDay: testDate, startOffset: 3600)  // 1시간 후
        let healthKit2 = makeHealthKitData(yearMonthDay: testDate, startOffset: 7200)  // 2시간 후
        let healthKit3 = makeHealthKitData(yearMonthDay: testDate, startOffset: 10800) // 3시간 후

        let expectedValue = makeExpectedDailyRecords(
            forWeekContaining: testDate,
            healthKitDatas: [testDate: [healthKit1, healthKit2, healthKit3]]
        )

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.currentWeekDates = makeWeekDates(containing: testDate)
        initialState.healthKitDatas = [testDate: [healthKit1, healthKit2, healthKit3]]

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        await store.send(.mergeDailyRecords(
            healthKitDatas: initialState.healthKitDatas,
            runningRecords: initialState.runningRecords
        )) {
            $0.isLoading = false
            $0.dailyRecords = expectedValue
        }
    }

    // MARK: - AddRecord Integration Tests

    @Test("createRecord는 AddRecord를 추가 모드로 표시")
    func createRecordOpensAddRecordInAddMode() async {
        let testDate = makeTodayYearMonthDay()
        let healthKitData = makeHealthKitData(yearMonthDay: testDate)

        let store = TestStore(
            initialState: DailyDetailFeature.State(selectedDate: testDate)
        ) {
            DailyDetailFeature()
        }

        store.exhaustivity = .off

        await store.send(.createRecord(healthKitData))

        #expect(store.state.addRecord != nil)
        #expect(store.state.addRecord?.existingRecord == nil)
        #expect(store.state.addRecord?.healthKitData.data == healthKitData)
    }

    @Test("editRecord는 AddRecord를 편집 모드로 표시")
    func editRecordOpensAddRecordInEditMode() async {
        let testDate = makeTodayYearMonthDay()
        let runningRecord = makeRunningRecord(yearMonthDay: testDate)

        let store = TestStore(
            initialState: DailyDetailFeature.State(selectedDate: testDate)
        ) {
            DailyDetailFeature()
        }

        await store.send(.editRecord(runningRecord)) {
            $0.addRecord = AddRecordFeature.State(
                existingRecord: runningRecord,
                healthKitData: nil
            )
        }
    }

    @Test("addRecord dismiss 시 시트 닫힘")
    func addRecordDismissClosesSheet() async {
        var initialState = DailyDetailFeature.State()
        initialState.addRecord = AddRecordFeature.State(
            existingRecord: nil,
            healthKitData: nil
        )

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        await store.send(.addRecord(.dismiss)) {
            $0.addRecord = nil
        }
    }

    @Test("addRecord recordSaved 시 캐시 무효화 및 주 단위 새로고침")
    func addRecordSavedClearsCacheAndRefetchesWeek() async {
        let testDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: testDate)
        let runningRecord = makeRunningRecord(yearMonthDay: testDate)
        let groupedRunningRecords = makeGroupedRunningRecords([(testDate, runningRecord)])
        var expectedValue = makeDailyRecords(healthKitDatas: [:], runningRecords: groupedRunningRecords, weekDates: weekDates)

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.currentWeekDates = makeWeekDates(containing: testDate)
        initialState.addRecord = AddRecordFeature.State(
            existingRecord: nil,
            healthKitData: nil
        )

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchRecords = { _, _ in [runningRecord] }
            $0.healthKitClient.ensureAuthorizationIfNeeded = {}
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in [] }
        }

        await store.send(.addRecord(.presented(.recordSaved))) {
            $0.addRecord = nil
            $0.dailyRecords.removeAll()
        }

        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.healthKitDatasFetched)

        await store.receive(\.runningRecordsFetched) {
            $0.runningRecords[testDate] = [runningRecord]
        }

        await store.receive(\.mergeDailyRecords) {
            $0.isLoading = false
            $0.dailyRecords = expectedValue

        }
    }

    // MARK: - Calendar Integration Tests

    @Test("calendarButtonTapped 시 Calendar 시트 표시")
    func calendarButtonTappedOpensCalendarSheet() async {
        let testDate = makeTodayYearMonthDay()

        let store = TestStore(
            initialState: DailyDetailFeature.State(selectedDate: testDate)
        ) {
            DailyDetailFeature()
        }

        await store.send(.calendarButtonTapped) {
            $0.calendar = CalendarFeature.State(selectedDate: testDate)
        }
    }

    @Test("calendar dismiss 시 시트 닫힘")
    func calendarDismissClosesSheet() async {
        let testDate = makeTodayYearMonthDay()

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.calendar = CalendarFeature.State(selectedDate: testDate)

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        await store.send(.calendar(.dismiss)) {
            $0.calendar = nil
        }
    }

    @Test("calendar navigateToDiary 시 주와 날짜 변경 및 캐시 미스면 fetch")
    func calendarNavigateToDiaryChangesWeekAndDateWithCacheMiss() async {
        let currentDate = makeYearMonthDay(year: 2025, month: 11, day: 27)
        let selectedDate = makeYearMonthDay(year: 2025, month: 12, day: 10) // 다른 주

        var initialState = DailyDetailFeature.State(selectedDate: currentDate)
        initialState.currentWeekDates = makeWeekDates(containing: currentDate)
        initialState.calendar = CalendarFeature.State(selectedDate: selectedDate)

        let expectedValue = makeExpectedDailyRecords(
            forWeekContaining: selectedDate,
            healthKitDatas: [:],
            runningRecords: [:]
        )

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchRecords = { _, _ in [] }
            $0.healthKitClient.ensureAuthorizationIfNeeded = {}
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in [] }
        }

        await store.send(.calendar(.presented(.navigateToDiary))) {
            $0.calendar = nil
            $0.currentWeekDates = makeWeekDates(containing: selectedDate)
            $0.selectedDate = selectedDate
        }

        // 캐시 미스로 fetch 발생
        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.healthKitDatasFetched)

        await store.receive(\.runningRecordsFetched)

        await store.receive(\.mergeDailyRecords) {
            $0.isLoading = false
            $0.dailyRecords = expectedValue
        }
    }

    // MARK: - Computed Properties Tests

    @Test("currentDailyRecord는 선택된 날짜의 기록 반환")
    func currentDailyRecordReturnsCorrectRecord() async {
        let testDate = makeTodayYearMonthDay()
        let dailyRecord = DailyRecord(
            yearMonthDay: testDate,
            healthKitDatas: [],
            savedRecords: []
        )

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dailyRecords = [testDate: dailyRecord]

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        #expect(store.state.currentDailyRecord == dailyRecord)
    }

    @Test("currentDailyRecord는 캐시되지 않은 날짜면 nil 반환")
    func currentDailyRecordReturnsNilWhenNotCached() async {
        let testDate = makeTodayYearMonthDay()

        let initialState = DailyDetailFeature.State(selectedDate: testDate)

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        #expect(store.state.currentDailyRecord == nil)
    }

    // MARK: - Error Handling Tests

    @Test("weekRecordsFetchFailed 시 에러 상태 설정")
    func weekRecordsFetchFailedSetsErrorState() async {
        let error = DailyDetailError.fetchFailed(underlyingError: "Network error")

        let store = TestStore(initialState: DailyDetailFeature.State(isLoading: true)) {
            DailyDetailFeature()
        }

        await store.send(.weekRecordsFetchFailed(error)) {
            $0.isLoading = false
            $0.error = error
        }
    }

    @Test("조회 실패 시 캐시가 손상되지 않음")
    func fetchFailureDoesNotCorruptCache() async {
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "Test error" }
        }

        let testDate = makeTodayYearMonthDay()
        let existingRecord = DailyRecord(
            yearMonthDay: testDate,
            healthKitDatas: [],
            savedRecords: []
        )

        var initialState = DailyDetailFeature.State()
        initialState.currentWeekDates = makeWeekDates(containing: testDate)
        initialState.dailyRecords = [testDate: existingRecord]

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.runningRecordClient.fetchRecords = { _, _ in
                throw TestError()
            }
            $0.healthKitClient.ensureAuthorizationIfNeeded = {}
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in [] }
        }

        await store.send(.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetchFailed) {
            $0.isLoading = false
            $0.error = .fetchFailed(underlyingError: "Test error")

            // 기존 캐시는 그대로 유지되어야 함
            #expect($0.dailyRecords[testDate] == existingRecord)
        }
    }
}

// MARK: - Test Helpers

extension DailyDetailFeatureTests {
    /// 오늘 날짜의 YearMonthDay 반환
    private func makeTodayYearMonthDay() -> YearMonthDay {
        YearMonthDay(date: Date())
    }

    /// YearMonthDay 생성 헬퍼
    /// - Parameters:
    ///   - year: 연도 (기본값: 현재 연도)
    ///   - month: 월 (기본값: 1)
    ///   - day: 일 (기본값: 1)
    /// - Returns: 지정된 날짜의 YearMonthDay
    private func makeYearMonthDay(
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
    private func makeRandomYearMonthDay(excluding: [YearMonthDay]? = nil) -> YearMonthDay {
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

    /// HealthKitData 생성 헬퍼
    private func makeHealthKitData(
        yearMonthDay: YearMonthDay,
        distance: Double = 5.0,
        startOffset: TimeInterval = 0
    ) -> HealthKitData {
        let startDate = yearMonthDay.toDate().addingTimeInterval(startOffset)
        return HealthKitData(
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
    private func makeRunningRecord(
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
    private func makeGroupedHealthKitData(
        _ data: [(YearMonthDay, HealthKitData)]
    ) -> [YearMonthDay: [HealthKitData]] {
        Dictionary(grouping: data.map { $1 }, by: { $0.yearMonthDay })
    }

    /// 그룹화된 RunningRecord 생성 헬퍼
    private func makeGroupedRunningRecords(
        _ records: [(YearMonthDay, RunningRecord)]
    ) -> [YearMonthDay: [RunningRecord]] {
        Dictionary(grouping: records.map { $1 }, by: { $0.yearMonthDay })
    }

    /// 주 날짜 배열 생성 헬퍼
    private func makeWeekDates(containing date: YearMonthDay) -> [YearMonthDay] {
        DateHelper.getWeekDates(for: date.toDate()).map { YearMonthDay(date: $0) }
    }

    private func makeDailyRecords(
        healthKitDatas: [YearMonthDay: [HealthKitData]],
        runningRecords: [YearMonthDay: [RunningRecord]],
        weekDates: [YearMonthDay]
    ) -> [YearMonthDay: DailyRecord] {
        var dailyRecords: [YearMonthDay: DailyRecord] = [:]
        for weekDate in weekDates {
            let runningRecord = runningRecords[weekDate] ?? []
            let healthKitData = healthKitDatas[weekDate] ?? []
            let filteredHealthKitData = healthKitData.filter { data in !runningRecord.contains(where: { $0.startTime == data.startDate }) }
            let dailyRecord = DailyRecord(
                yearMonthDay: weekDate,
                healthKitDatas: filteredHealthKitData,
                savedRecords: runningRecords[weekDate] ?? []
            )
            dailyRecords.updateValue(dailyRecord, forKey: weekDate)
        }
        return dailyRecords
    }

    /// ExpectedValue 생성 간소화 헬퍼 - 주어진 데이터로부터 예상되는 DailyRecords를 자동으로 생성
    private func makeExpectedDailyRecords(
        forWeekContaining date: YearMonthDay,
        healthKitDatas: [YearMonthDay: [HealthKitData]] = [:],
        runningRecords: [YearMonthDay: [RunningRecord]] = [:]
    ) -> [YearMonthDay: DailyRecord] {
        let weekDates = makeWeekDates(containing: date)
        return makeDailyRecords(
            healthKitDatas: healthKitDatas,
            runningRecords: runningRecords,
            weekDates: weekDates
        )
    }
}
