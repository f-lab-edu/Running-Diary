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
            $0.errorMessage = nil
        }
        
        await store.receive(\.weekRecordsFetchedSuccess) {
            $0.isLoading = false
            let normalizedDate = Calendar.current.startOfDay(for: mockRecord.date)
            $0.cachedRecords = [normalizedDate: mockRecord]
            $0.errorMessage = nil
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
            $0.errorMessage = nil
        }
        
        await store.receive(\.weekRecordsFetchedSuccess) {
            $0.isLoading = false
            let normalizedDate = calendar.startOfDay(for: mockRecord.date)
            $0.cachedRecords = [normalizedDate: mockRecord]
            $0.errorMessage = nil
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
        initialState.cachedRecords = [normalizedDate: mockRecord]
        
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
        
        let store = TestStore(
            initialState: DailyDetailFeature.State(isLoading: true)
        ) {
            DailyDetailFeature()
        }
        
        await store.send(.weekRecordsFetchedSuccess([mockRecord])) {
            $0.isLoading = false
            let normalizedDate = calendar.startOfDay(for: mockRecord.date)
            $0.cachedRecords = [normalizedDate: mockRecord]
            $0.errorMessage = nil
        }
    }
    
    @Test("주 단위 기록 조회 실패 시 에러 메시지 표시")
    func weekRecordsFetchFailureDisplaysError() async {
        let errorMessage = "네트워크 연결 실패"
        
        let store = TestStore(
            initialState: DailyDetailFeature.State(isLoading: true)
        ) {
            DailyDetailFeature()
        }
        
        await store.send(.weekRecordsFetchedFailure(errorMessage)) {
            $0.isLoading = false
            $0.errorMessage = "기록을 불러올 수 없습니다: \(errorMessage)"
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
                cachedRecords: [normalizedDate: mockRecord]
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
            $0.errorMessage = nil
        }
        
        await store.receive(\.weekRecordsFetchedSuccess) {
            $0.isLoading = false
            let normalizedDate = calendar.startOfDay(for: savedRecord.date)
            $0.cachedRecords = [normalizedDate: savedRecord]
            $0.errorMessage = nil
        }
    }
}
