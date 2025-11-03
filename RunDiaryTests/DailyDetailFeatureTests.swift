//
//  DailyDetailFeatureTests.swift
//  RunDiaryTests
//
//  Created by Claude on 10/21/25.
//

import ComposableArchitecture
import Foundation
import Models

import Testing

@testable import RunDiary

@Suite("DailyDetail Feature")
struct DailyDetailFeatureTests {

    // MARK: - Test Helpers

    /// 특정 날짜들로 캐시 Dictionary 생성
    private func makeCachedRecords(dates: [Date], records: [Date: RunningRecord]) -> [Date: RunningRecord?] {
        var cache: [Date: RunningRecord?] = [:]
        let calendar = Calendar.current
        for date in dates {
            let normalizedDate = calendar.startOfDay(for: date)
            cache[normalizedDate] = records[normalizedDate]
        }
        return cache
    }

    /// 테스트용 RunningRecord 생성
    private func makeMockRecord(date: Date, distance: Double = 5.0) -> RunningRecord {
        return RunningRecord(
            date: date,
            distanceInKilometers: distance,
            durationInSeconds: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            runningStyle: .midfoot,
            condition: RunningCondition(meal: true, alcohol: false)
        )
    }

    // MARK: - Tests

    @Test("앱 시작 시 날짜 배열 초기화 및 주 단위 기록 조회")
    func onAppearInitializesDatesAndFetchesWeekRecords() async {
        let testDate = Date()
        let mockRecord = RunningRecord(
            date: testDate,
            distanceInKilometers: 5.0,
            durationInSeconds: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            runningStyle: .midfoot,
            condition: RunningCondition(meal: true, alcohol: false)
        )
        
        let store = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        } withDependencies: {
            $0.repositoryClient.fetchRecords = { _, _ in [mockRecord] }
        }
        
        await store.send(.onAppear) {
            $0.currentWeekDates = DateHelper.getWeekDates(for: Date())
        }
        
        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }
        
        await store.receive(\.weekRecordsFetchedSuccess) {
            $0.isLoading = false
            // currentWeekDates의 모든 날짜가 캐시에 저장됨
            let calendar = Calendar.current
            let recordsByDate = [calendar.startOfDay(for: mockRecord.date): mockRecord]
            for date in $0.currentWeekDates {
                let normalizedDate = calendar.startOfDay(for: date)
                $0.cachedRecords[normalizedDate] = recordsByDate[normalizedDate]
            }
            $0.error = nil
        }
    }
    
    @Test("날짜 선택 시 캐시 미스면 주 단위 기록 조회")
    func dateSelectionWithCacheMissTriggersWeekFetch() async {
        let calendar = Calendar.current
        let selectedDate = calendar.date(byAdding: .day, value: 1, to: Date())!
        let mockRecord = RunningRecord(
            date: selectedDate,
            distanceInKilometers: 3.0,
            durationInSeconds: 1200,
            averagePace: "6'40\"",
            averageHeartRate: 145,
            averageCadence: 165,
            runningStyle: .forefoot,
            condition: RunningCondition(meal: true, alcohol: false)
        )
        
        var initialState = DailyDetailFeature.State()
        initialState.currentWeekDates = DateHelper.getWeekDates(for: selectedDate)
        
        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.repositoryClient.fetchRecords = { _, _ in [mockRecord] }
        }
        
        await store.send(.dateSelected(selectedDate)) {
            $0.selectedDate = selectedDate
        }
        
        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }
        
        await store.receive(\.weekRecordsFetchedSuccess) {
            $0.isLoading = false
            // currentWeekDates의 모든 날짜가 캐시에 저장됨
            let recordsByDate = [calendar.startOfDay(for: mockRecord.date): mockRecord]
            for date in $0.currentWeekDates {
                let normalizedDate = calendar.startOfDay(for: date)
                $0.cachedRecords[normalizedDate] = recordsByDate[normalizedDate]
            }
            $0.error = nil
        }
    }
    
    @Test("날짜 선택 시 캐시 히트면 fetch 생략")
    func dateSelectionWithCacheHitSkipsFetch() async {
        let calendar = Calendar.current
        let selectedDate = Date()
        let normalizedDate = calendar.startOfDay(for: selectedDate)
        let mockRecord = RunningRecord(
            date: selectedDate,
            distanceInKilometers: 3.0,
            durationInSeconds: 1200,
            averagePace: "6'40\"",
            averageHeartRate: 145,
            averageCadence: 165,
            runningStyle: .forefoot,
            condition: RunningCondition(meal: true, alcohol: false)
        )
        
        var initialState = DailyDetailFeature.State()
        initialState.cachedRecords = [normalizedDate: .some(mockRecord)]

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }
        
        // 캐시에 이미 있으므로 fetch가 발생하지 않음
        await store.send(.dateSelected(selectedDate)) {
            $0.selectedDate = selectedDate
        }
    }
    
    @Test("주 단위 기록 조회 성공 시 캐시 업데이트")
    func weekRecordsFetchSuccessUpdatesCache() async {
        let calendar = Calendar.current
        let testDate = Date()
        let mockRecord = RunningRecord(
            date: testDate,
            distanceInKilometers: 10.0,
            durationInSeconds: 3000,
            averagePace: "5'00\"",
            averageHeartRate: 160,
            averageCadence: 180,
            runningStyle: .midfoot,
            condition: RunningCondition(sleep: 7, meal: true, alcohol: false)
        )

        var initialState = DailyDetailFeature.State(isLoading: true)
        initialState.currentWeekDates = DateHelper.getWeekDates(for: testDate)

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }
        
        await store.send(.weekRecordsFetchedSuccess([mockRecord])) {
            $0.isLoading = false
            // currentWeekDates의 모든 날짜가 캐시에 저장됨
            let recordsByDate = [calendar.startOfDay(for: mockRecord.date): mockRecord]
            for date in $0.currentWeekDates {
                let normalizedDate = calendar.startOfDay(for: date)
                $0.cachedRecords[normalizedDate] = recordsByDate[normalizedDate]
            }
            $0.error = nil
        }
    }
    
    @Test("주 단위 기록 조회 실패 시 에러 메시지 표시")
    func weekRecordsFetchFailureDisplaysError() async {
        let underlyingErrorMessage = "네트워크 연결 실패"
        let error = DailyDetailError.fetchFailed(underlyingError: underlyingErrorMessage)

        let store = TestStore(initialState: DailyDetailFeature.State(isLoading: true)) {
            DailyDetailFeature()
        }

        await store.send(.weekRecordsFetchedFailure(error)) {
            $0.isLoading = false
            $0.error = error
        }
    }
    
    @Test("기록 없을 때 추가 모드로 화면 표시")
    func showAddRecordWithNoExistingRecordUsesAddMode() async {
        let testDate = Date()
        
        let store = TestStore(
            initialState: DailyDetailFeature.State(
                selectedDate: testDate
            )
        ) {
            DailyDetailFeature()
        }
        
        await store.send(.showAddRecord) {
            $0.addRecord = AddRecordFeature.State(
                date: testDate
            )
        }
    }
    
    @Test("기록 있을 때 편집 모드로 화면 표시")
    func showAddRecordWithExistingRecordUsesEditMode() async {
        let calendar = Calendar.current
        let testDate = Date()
        let normalizedDate = calendar.startOfDay(for: testDate)
        let mockRecord = RunningRecord(
            date: testDate,
            distanceInKilometers: 5.0,
            durationInSeconds: 1500,
            averagePace: "5'00\"",
            averageHeartRate: 155,
            averageCadence: 175,
            runningStyle: .forefoot,
            condition: RunningCondition(meal: false, alcohol: false)
        )
        
        let store = TestStore(
            initialState: DailyDetailFeature.State(
                selectedDate: testDate,
                cachedRecords: [normalizedDate: .some(mockRecord)]
            )
        ) {
            DailyDetailFeature()
        }
        
        await store.send(.showAddRecord) {
            $0.addRecord = AddRecordFeature.State(
                date: testDate,
                existingRecord: mockRecord
            )
        }
    }
    
    @Test("기록 저장 후 캐시 무효화 및 주 단위 새로고침")
    func addRecordSaveClearsCacheAndRefetchesWeek() async {
        let calendar = Calendar.current
        let testDate = Date()
        let savedRecord = RunningRecord(
            date: testDate,
            distanceInKilometers: 8.0,
            durationInSeconds: 2400,
            averagePace: "5'00\"",
            averageHeartRate: 158,
            averageCadence: 178,
            runningStyle: .midfoot,
            condition: RunningCondition(meal: true, alcohol: false)
        )
        
        var initialState = DailyDetailFeature.State(
            selectedDate: testDate,
            addRecord: AddRecordFeature.State(date: testDate)
        )
        initialState.currentWeekDates = DateHelper.getWeekDates(for: testDate)
        
        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.repositoryClient.fetchRecords = { _, _ in [savedRecord] }
        }
        
        await store.send(.addRecord(.presented(.recordSaved(savedRecord)))) {
            $0.addRecord = nil
            $0.cachedRecords.removeAll()
        }
        
        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }
        
        await store.receive(\.weekRecordsFetchedSuccess) {
            $0.isLoading = false
            // currentWeekDates의 모든 날짜가 캐시에 저장됨
            let recordsByDate = [calendar.startOfDay(for: savedRecord.date): savedRecord]
            for date in $0.currentWeekDates {
                let normalizedDate = calendar.startOfDay(for: date)
                $0.cachedRecords[normalizedDate] = recordsByDate[normalizedDate]
            }
            $0.error = nil
        }
    }

    @Test("nil 값이 캐시되어 있으면 fetch 생략")
    func dateSelectionWithNilCacheHitSkipsFetch() async {
        let calendar = Calendar.current
        let selectedDate = Date()
        let normalizedDate = calendar.startOfDay(for: selectedDate)

        var initialState = DailyDetailFeature.State()
        // nil 값을 명시적으로 캐시에 저장 (기록이 없는 날짜)
        initialState.cachedRecords = [normalizedDate: nil]

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // 캐시에 nil로 저장되어 있으므로 fetch가 발생하지 않음
        await store.send(.dateSelected(selectedDate)) {
            $0.selectedDate = selectedDate
        }

        // fetchWeekRecords가 발생하지 않음을 확인
        // (추가 액션을 받지 않음)
    }

    @Test("주 단위 조회 시 일부 날짜만 기록 있을 때 전체 날짜 캐싱")
    func weekRecordsFetchWithPartialRecordsUpdatesAllDates() async {
        let calendar = Calendar.current
        let today = Date()

        let currentWeekDates = DateHelper.getWeekDates(for: today)

        var initialState = DailyDetailFeature.State(isLoading: true)
        initialState.currentWeekDates = currentWeekDates
        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // 7일 중 2개만 레코드가 있는 경우
        guard let first = currentWeekDates.first, let last = currentWeekDates.last else { return }
        let record1 = makeMockRecord(date: first, distance: 5.0)
        let record2 = makeMockRecord(date: last, distance: 7.0)

        await store.send(.weekRecordsFetchedSuccess([record1, record2])) {
            $0.isLoading = false

            // currentWeekDates의 모든 날짜(7일)가 캐시에 저장됨
            let recordsByDate: [Date: RunningRecord] = [
                calendar.startOfDay(for: first): record1,
                calendar.startOfDay(for: last): record2
            ]

            for date in $0.currentWeekDates {
                let normalizedDate = calendar.startOfDay(for: date)
                // 레코드가 있는 날짜는 값 저장, 없는 날짜는 nil 저장
                $0.cachedRecords[normalizedDate] = recordsByDate[normalizedDate]
            }

            $0.error = nil
        }

        // 캐시에 7개 날짜 모두 저장되었는지 확인
        #expect(store.state.cachedRecords.count == 7)

        // 레코드가 있는 날짜는 값이 있고
        let firstKey = calendar.startOfDay(for: first)
        #expect(store.state.cachedRecords[firstKey] == record1)

        // 레코드가 없는 날짜는 nil로 저장됨 (키는 존재하지만 값은 nil)
        let firstNextDate = calendar.date(byAdding: .day, value: 1, to: first)!
        let firstNextDateKey = calendar.startOfDay(for: firstNextDate)
        #expect(store.state.cachedRecords.keys.contains(firstNextDateKey))
        // Double optional: dictionary returns RunningRecord??, unwrap outer to check inner nil
        if let wrappedValue = store.state.cachedRecords[firstNextDateKey] {
            #expect(wrappedValue == nil)
        } else {
            Issue.record("Expected key to exist in cache")
        }
    }

    @Test("주 변경 시 캐시 미스로 fetch 발생")
    func weekChangedWithCacheMissTriggersWeekFetch() async {
        let calendar = Calendar.current
        let testDate = Date()

        // 현재 주 데이터 미리 캐싱
        let currentWeekDates = DateHelper.getWeekDates(for: testDate)
        let mockRecord = makeMockRecord(date: testDate)

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.currentWeekDates = currentWeekDates
        initialState.cachedRecords = makeCachedRecords(
            dates: currentWeekDates,
            records: [calendar.startOfDay(for: testDate): mockRecord]
        )

        // 다음 주 데이터를 반환할 mock
        let nextWeekStart = DateHelper.addWeeks(1, to: currentWeekDates.first!)
        let nextWeekDates = DateHelper.getWeekDates(for: nextWeekStart)
        let nextWeekRecord = makeMockRecord(date: nextWeekStart)

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.repositoryClient.fetchRecords = { _, _ in [nextWeekRecord] }
        }

        // 다음 주로 이동
        await store.send(.weekChanged(offset: 1)) {
            $0.currentWeekDates = nextWeekDates

            // selectedDate가 같은 요일로 이동
            let currentWeekday = calendar.component(.weekday, from: testDate)
            if let newSelectedDate = nextWeekDates.first(where: {
                calendar.component(.weekday, from: $0) == currentWeekday
            }) {
                $0.selectedDate = newSelectedDate
            } else {
                $0.selectedDate = nextWeekStart
            }
        }

        // 캐시 미스로 fetch 발생
        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetchedSuccess) {
            $0.isLoading = false
            let recordsByDate = [calendar.startOfDay(for: nextWeekStart): nextWeekRecord]
            for date in $0.currentWeekDates {
                let normalizedDate = calendar.startOfDay(for: date)
                $0.cachedRecords[normalizedDate] = recordsByDate[normalizedDate]
            }
            $0.error = nil
        }
    }

    @Test("주 변경 시 캐시 히트로 fetch 생략")
    func weekChangedWithCacheHitSkipsFetch() async {
        let calendar = Calendar.current
        let testDate = Date()

        // 현재 주와 다음 주 데이터를 모두 미리 캐싱
        let currentWeekDates = DateHelper.getWeekDates(for: testDate)
        let nextWeekStart = DateHelper.addWeeks(1, to: currentWeekDates.first!)
        let nextWeekDates = DateHelper.getWeekDates(for: nextWeekStart)

        let currentWeekRecord = makeMockRecord(date: testDate)
        let nextWeekRecord = makeMockRecord(date: nextWeekStart)

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.currentWeekDates = currentWeekDates

        // 현재 주와 다음 주 모두 캐싱
        var allRecords: [Date: RunningRecord] = [:]
        allRecords[calendar.startOfDay(for: testDate)] = currentWeekRecord
        allRecords[calendar.startOfDay(for: nextWeekStart)] = nextWeekRecord

        // 현재 주 캐싱
        initialState.cachedRecords = makeCachedRecords(dates: currentWeekDates, records: allRecords)
        // 다음 주도 캐싱
        for date in nextWeekDates {
            let normalizedDate = calendar.startOfDay(for: date)
            initialState.cachedRecords[normalizedDate] = allRecords[normalizedDate]
        }

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // 다음 주로 이동
        await store.send(.weekChanged(offset: 1)) {
            $0.currentWeekDates = nextWeekDates

            // selectedDate가 같은 요일로 이동
            let currentWeekday = calendar.component(.weekday, from: testDate)
            if let newSelectedDate = nextWeekDates.first(where: {
                calendar.component(.weekday, from: $0) == currentWeekday
            }) {
                $0.selectedDate = newSelectedDate
            } else {
                $0.selectedDate = nextWeekStart
            }
        }

        // 캐시 히트로 fetch가 발생하지 않음
        // (추가 액션을 받지 않음)
    }

    @Test("여러 주를 이동하며 캐시가 누적됨")
    func multipleWeekNavigationAccumulatesCache() async {
        let calendar = Calendar.current
        let testDate = Date()

        // 현재 주 데이터
        let currentWeekDates = DateHelper.getWeekDates(for: testDate)
        let currentWeekRecord = makeMockRecord(date: testDate)

        // 다음 주 데이터
        let nextWeekStart = DateHelper.addWeeks(1, to: currentWeekDates.first!)
        let nextWeekDates = DateHelper.getWeekDates(for: nextWeekStart)
        let nextWeekRecord = makeMockRecord(date: nextWeekStart, distance: 7.0)

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.currentWeekDates = currentWeekDates

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.repositoryClient.fetchRecords = { start, end in
                // 현재 주 조회
                if calendar.isDate(start, inSameDayAs: currentWeekDates.first!) {
                    return [currentWeekRecord]
                }
                // 다음 주 조회
                else if calendar.isDate(start, inSameDayAs: nextWeekDates.first!) {
                    return [nextWeekRecord]
                }
                return []
            }
        }

        // 1단계: 현재 주 조회
        await store.send(.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetchedSuccess) {
            $0.isLoading = false
            let recordsByDate = [calendar.startOfDay(for: testDate): currentWeekRecord]
            for date in $0.currentWeekDates {
                let normalizedDate = calendar.startOfDay(for: date)
                $0.cachedRecords[normalizedDate] = recordsByDate[normalizedDate]
            }
            $0.error = nil
        }

        // 캐시에 7개 날짜 저장됨
        #expect(store.state.cachedRecords.count == 7)

        // 2단계: 다음 주로 이동
        await store.send(.weekChanged(offset: 1)) {
            $0.currentWeekDates = nextWeekDates
            let currentWeekday = calendar.component(.weekday, from: testDate)
            if let newSelectedDate = nextWeekDates.first(where: {
                calendar.component(.weekday, from: $0) == currentWeekday
            }) {
                $0.selectedDate = newSelectedDate
            } else {
                $0.selectedDate = nextWeekStart
            }
        }

        await store.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetchedSuccess) {
            $0.isLoading = false
            let recordsByDate = [calendar.startOfDay(for: nextWeekStart): nextWeekRecord]
            for date in $0.currentWeekDates {
                let normalizedDate = calendar.startOfDay(for: date)
                $0.cachedRecords[normalizedDate] = recordsByDate[normalizedDate]
            }
            $0.error = nil
        }

        // 캐시에 14개 날짜 누적됨 (현재 주 7개 + 다음 주 7개)
        #expect(store.state.cachedRecords.count == 14)

        // 3단계: 현재 주로 복귀 (fetch 없이 캐시 사용)
        await store.send(.weekChanged(offset: -1)) {
            $0.currentWeekDates = currentWeekDates
            let currentWeekday = calendar.component(.weekday, from: $0.selectedDate)
            if let newSelectedDate = currentWeekDates.first(where: {
                calendar.component(.weekday, from: $0) == currentWeekday
            }) {
                $0.selectedDate = newSelectedDate
            } else {
                $0.selectedDate = currentWeekDates.first!
            }
        }

        // fetch가 발생하지 않음 (캐시 히트)
    }

    @Test("currentRecord가 nil 캐시를 올바르게 처리")
    func currentRecordReturnsNilForNilCache() async {
        let calendar = Calendar.current
        let testDate = Date()
        let normalizedDate = calendar.startOfDay(for: testDate)

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        // nil 값을 명시적으로 캐시에 저장
        initialState.cachedRecords = [normalizedDate: nil]

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // currentRecord가 nil을 안전하게 반환하는지 확인
        #expect(store.state.currentRecord == nil)

        // 캐시에는 키가 존재함
        #expect(store.state.cachedRecords.keys.contains(normalizedDate))
    }

    @Test("시간이 다른 같은 날짜는 동일하게 처리됨")
    func dateNormalizationWorksCorrectly() async {
        let calendar = Calendar.current

        // 같은 날짜, 다른 시간
        let morningDate = calendar.date(from: DateComponents(year: 2025, month: 10, day: 30, hour: 9, minute: 0))!
        let eveningDate = calendar.date(from: DateComponents(year: 2025, month: 10, day: 30, hour: 21, minute: 30))!

        let mockRecord = makeMockRecord(date: morningDate)
        let normalizedDate = calendar.startOfDay(for: morningDate)

        var initialState = DailyDetailFeature.State(selectedDate: morningDate)
        // 아침 시간으로 레코드 캐싱
        initialState.cachedRecords = [normalizedDate: .some(mockRecord)]

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // 저녁 시간으로 같은 날짜 선택 시 캐시 히트
        await store.send(.dateSelected(eveningDate)) {
            $0.selectedDate = eveningDate
        }

        // fetch가 발생하지 않음 (정규화로 인해 캐시 히트)
        // currentRecord는 아침에 저장한 레코드를 반환
        #expect(store.state.currentRecord == mockRecord)
    }

    @Test("조회 실패 시 캐시가 손상되지 않음")
    func fetchFailureDoesNotCorruptCache() async {
        let calendar = Calendar.current
        let testDate = Date()

        // 빈 캐시에서 시작
        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.currentWeekDates = DateHelper.getWeekDates(for: testDate)

        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "Test network error" }
        }

        let store = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.repositoryClient.fetchRecords = { _, _ in
                throw TestError()
            }
        }

        // fetch 시도 (실패)
        await store.send(.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await store.receive(\.weekRecordsFetchedFailure) {
            $0.isLoading = false
            $0.error = .fetchFailed(underlyingError: "Test network error")
        }

        // 실패 시 캐시는 비어있어야 함 (손상되지 않음)
        #expect(store.state.cachedRecords.isEmpty)
    }
}
