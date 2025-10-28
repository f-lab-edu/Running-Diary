//
//  DailyDetailFeatureTests.swift
//  RunDiaryTests
//
//  Created by Claude on 10/21/25.
//

import Testing
import ComposableArchitecture
import Foundation
@testable import RunDiary

@Suite("DailyDetail Feature")
struct DailyDetailFeatureTests {

    @Test("앱 시작 시 날짜 배열 초기화 및 기록 조회")
    func onAppearInitializesDatesAndFetchesRecord() async {
        let testDate = Date()
        let mockRecord = RunningRecord(
            date: testDate,
            distanceInKilometers: 5.0,
            condition: RunningCondition(meal: false, alcohol: false)
        )

        let store = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        } withDependencies: {
            $0.repositoryClient.fetch = { _ in mockRecord }
        }

        await store.send(.onAppear) {
            $0.currentWeekDates = DateHelper.getWeekDates(for: Date())
        }

        await store.receive(\.fetchRecordForSelectedDate) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.recordFetchedSuccess) {
            $0.isLoading = false
            $0.runningRecord = mockRecord
            $0.errorMessage = nil
        }
    }

    @Test("날짜 선택 시 기록 조회")
    func dateSelectionTriggersRecordFetch() async {
        let selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let mockRecord = RunningRecord(
            date: selectedDate,
            distanceInKilometers: 3.0,
            condition: RunningCondition(meal: true, alcohol: false)
        )

        let store = TestStore(initialState: DailyDetailFeature.State()) {
            DailyDetailFeature()
        } withDependencies: {
            $0.repositoryClient.fetch = { _ in mockRecord }
        }

        await store.send(.dateSelected(selectedDate)) {
            $0.selectedDate = selectedDate
        }

        await store.receive(\.fetchRecordForSelectedDate) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.recordFetchedSuccess) {
            $0.isLoading = false
            $0.runningRecord = mockRecord
            $0.errorMessage = nil
        }
    }

    @Test("기록 조회 성공 시 상태 업데이트")
    func recordFetchSuccessUpdatesState() async {
        let mockRecord = RunningRecord(
            date: Date(),
            distanceInKilometers: 10.0,
            condition: RunningCondition(sleep: 7, meal: true, alcohol: false)
        )

        let store = TestStore(initialState: DailyDetailFeature.State(isLoading: true)) {
            DailyDetailFeature()
        }

        await store.send(.recordFetchedSuccess(mockRecord)) {
            $0.isLoading = false
            $0.runningRecord = mockRecord
            $0.errorMessage = nil
        }
    }

    @Test("기록 조회 실패 시 에러 메시지 표시")
    func recordFetchFailureDisplaysError() async {
        let errorMessage = "네트워크 연결 실패"

        let store = TestStore(initialState: DailyDetailFeature.State(isLoading: true)) {
            DailyDetailFeature()
        }

        await store.send(.recordFetchedFailure(errorMessage)) {
            $0.isLoading = false
            $0.runningRecord = nil
            $0.errorMessage = "기록을 불러올 수 없습니다: \(errorMessage)"
        }
    }

    @Test("기록 없을 때 추가 모드로 화면 표시")
    func showAddRecordWithNoExistingRecordUsesAddMode() async {
        let testDate = Date()

        let store = TestStore(
            initialState: DailyDetailFeature.State(
                selectedDate: testDate,
                runningRecord: nil
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
        let testDate = Date()
        let mockRecord = RunningRecord(
            date: testDate,
            distanceInKilometers: 5.0,
            condition: RunningCondition(meal: false, alcohol: false)
        )

        let store = TestStore(
            initialState: DailyDetailFeature.State(
                selectedDate: testDate,
                runningRecord: mockRecord
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

    @Test("기록 저장 후 화면 닫기 및 새로고침")
    func addRecordSaveClosesSheetAndRefreshesRecord() async {
        let testDate = Date()
        let savedRecord = RunningRecord(
            date: testDate,
            distanceInKilometers: 8.0,
            condition: RunningCondition(meal: true, alcohol: false)
        )

        let store = TestStore(
            initialState: DailyDetailFeature.State(
                selectedDate: testDate,
                addRecord: AddRecordFeature.State(date: testDate)
            )
        ) {
            DailyDetailFeature()
        } withDependencies: {
            $0.repositoryClient.fetch = { _ in savedRecord }
        }

        await store.send(.addRecord(.presented(.satisfactionSaved(savedRecord)))) {
            $0.addRecord = nil
        }

        await store.receive(\.fetchRecordForSelectedDate) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.recordFetchedSuccess) {
            $0.isLoading = false
            $0.runningRecord = savedRecord
            $0.errorMessage = nil
        }
    }
}
