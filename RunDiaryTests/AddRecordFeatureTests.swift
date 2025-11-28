//
//  AddRecordFeatureTests.swift
//  RunDiaryTests
//
//  Created by Claude on 10/23/25.
//

import ComposableArchitecture
import Foundation
import Models

import Testing

@testable import RunDiary

@Suite("AddRecord Feature")
struct AddRecordFeatureTests {
    
    // MARK: - Initialization Tests
    
    @Test("Add mode: HealthKit 데이터와 함께 초기화")
    func initializeWithHealthKitData() async {
        let testDate = Date.now
        let healthKitData = HealthKitData(
            distance: 5.2,
            duration: 1800,
            averagePace: "5'30\"",
            averageHeartRate: 155,
            averageCadence: 180,
            routeData: nil,
            startDate: testDate,
            endDate: testDate.addingTimeInterval(1800)
        )
        
        let state = AddRecordFeature.State(healthKitData: healthKitData)
        
        #expect(state.mode == .add)
        #expect(state.healthKitData.data?.distance == 5.2)
        #expect(state.healthKitData.data?.duration == 1800)
        #expect(state.existingRecord == nil)
        #expect(state.weather == nil)
        #expect(state.selectedDifficultyLevel == nil)
    }
    
    @Test("Edit mode: 기존 레코드와 함께 초기화")
    func initializeWithExistingRecord() async {
        let testDate = Date.now
        let existingRecord = RunningRecord(
            yearMonthDay: YearMonthDay(date: testDate),
            distanceInKilometers: 5.2,
            durationInSeconds: 1800,
            averagePace: "5'30\"",
            averageHeartRate: 155,
            averageCadence: 180,
            painAreas: [.knee],
            runningStyle: .midfoot,
            condition: RunningCondition(
                sleep: 7,
                meal: true,
                alcohol: false,
                memo: "좋은 컨디션"
            ),
            shoes: "1",
            weather: WeatherData(temperature: 18.5, humidity: 60, windSpeed: 2.3),
            difficultyLevel: .hard,
            routeData: nil,
            hasMap: false,
            startTime: testDate,
            endTime: testDate.addingTimeInterval(1800)
        )
        
        let state = AddRecordFeature.State(existingRecord: existingRecord)
        
        #expect(state.mode == .edit)
        #expect(state.existingRecord != nil)
        #expect(state.condition.sleepHours == "7")
        #expect(state.condition.hadMeal == true)
        #expect(state.condition.hadAlcohol == false)
        #expect(state.condition.memo == "좋은 컨디션")
    }
    
    @Test("onAppear: Edit mode에서 기존 레코드 데이터 로드")
    func onAppearInEditModeLoadsExistingRecordData() async {
        let testDate = Date.now
        let existingRecord = RunningRecord(
            yearMonthDay: YearMonthDay(date: testDate),
            distanceInKilometers: 5.2,
            durationInSeconds: 1800,
            averagePace: "5'30\"",
            averageHeartRate: 155,
            averageCadence: 180,
            runningStyle: .midfoot,
            condition: RunningCondition(sleep: 7, meal: true, alcohol: false),
            shoes: "1",
            weather: WeatherData(temperature: 18.5, humidity: 60, windSpeed: 2.3),
            difficultyLevel: .hard,
            routeData: nil,
            hasMap: false,
            startTime: testDate,
            endTime: testDate.addingTimeInterval(1800)
        )
        
        let store = TestStore(
            initialState: AddRecordFeature.State(existingRecord: existingRecord)
        ) {
            AddRecordFeature()
        }
        
        await store.send(.onAppear) {
            $0.weather = existingRecord.weather
            $0.selectedDifficultyLevel = .hard
        }
    }
    
    // MARK: - Save Record Tests
    
    @Test("Add mode: 기록 저장 성공")
    func saveRecordInAddModeSucceeds() async {
        let testDate = Date.now
        let healthKitData = HealthKitData(
            distance: 5.0,
            duration: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            routeData: nil,
            startDate: testDate,
            endDate: testDate.addingTimeInterval(1800)
        )
        
        let mockWeather = WeatherData(temperature: 20.0, humidity: 55, windSpeed: 2.5)
        var savedRecord: RunningRecord?
        
        var initialState = AddRecordFeature.State(healthKitData: healthKitData)
        initialState.condition.selectedShoe = ShoeModel(name: "Nike Pegasus 40", brand: "Nike")
        initialState.condition.selectedRunningStyle = .midfoot
        initialState.condition.sleepHours = "8"
        initialState.condition.hadMeal = true
        initialState.selectedDifficultyLevel = .medium
        
        let store = TestStore(initialState: initialState) {
            AddRecordFeature()
        } withDependencies: {
            $0.weatherClient.fetchWeather = { _, _ in mockWeather }
            $0.runningRecordClient.save = { record in
                savedRecord = record
            }
            $0.dismiss = DismissEffect { }
        }
        
        await store.send(.saveRecord) {
            $0.isLoading = true
            $0.errorMassage = nil
        }
        
        await store.receive(\.recordSaved) {
            $0.isLoading = false
        }
        
        #expect(savedRecord != nil)
        #expect(savedRecord?.distanceInKilometers == 5.0)
    }
    
    @Test("Edit mode: 기록 업데이트 성공")
    func saveRecordInEditModeUpdatesRecord() async {
        let testDate = Date.now
        let recordId = UUID()
        let existingRecord = RunningRecord(
            id: recordId,
            yearMonthDay: YearMonthDay(date: testDate),
            distanceInKilometers: 3.0,
            durationInSeconds: 1500,
            averagePace: "5'00\"",
            averageHeartRate: 145,
            averageCadence: 165,
            runningStyle: .midfoot,
            condition: RunningCondition(meal: false, alcohol: false),
            shoes: "1",
            weather: nil,
            difficultyLevel: nil,
            routeData: nil,
            hasMap: false,
            startTime: testDate,
            endTime: testDate.addingTimeInterval(1500)
        )
        
        let healthKitData = HealthKitData(
            distance: 5.5,
            duration: 2100,
            averagePace: "6'20\"",
            averageHeartRate: 150,
            averageCadence: 170,
            routeData: nil,
            startDate: testDate,
            endDate: testDate.addingTimeInterval(2100)
        )
        
        let mockWeather = WeatherData(temperature: 18.0, humidity: 65, windSpeed: 1.5)
        var updatedRecord: RunningRecord?
        
        var initialState = AddRecordFeature.State(
            existingRecord: existingRecord,
            healthKitData: healthKitData
        )
        initialState.condition.selectedShoe = ShoeModel(name: "Nike Pegasus 40", brand: "Nike")
        initialState.condition.selectedRunningStyle = .forefoot
        initialState.condition.sleepHours = "7"
        initialState.selectedDifficultyLevel = .hard
        
        let store = TestStore(initialState: initialState) {
            AddRecordFeature()
        } withDependencies: {
            $0.weatherClient.fetchWeather = { _, _ in mockWeather }
            $0.runningRecordClient.update = { record in
                updatedRecord = record
            }
            $0.dismiss = DismissEffect { }
        }
        
        await store.send(.saveRecord) {
            $0.isLoading = true
            $0.errorMassage = nil
        }
        
        await store.receive(\.recordSaved) {
            $0.isLoading = false
        }
        
        #expect(updatedRecord != nil)
        #expect(updatedRecord?.id == recordId)
        #expect(updatedRecord?.distanceInKilometers == 5.5)
    }
    
    @Test("기록 저장 실패 시 에러 메시지 표시")
    func saveRecordFailureShowsError() async {
        let testDate = Date.now
        let healthKitData = HealthKitData(
            distance: 5.0,
            duration: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            routeData: nil,
            startDate: testDate,
            endDate: testDate.addingTimeInterval(1800)
        )
        
        var initialState = AddRecordFeature.State(healthKitData: healthKitData)
        initialState.condition.selectedShoe = ShoeModel(name: "Nike Pegasus 40", brand: "Nike")
        initialState.condition.selectedRunningStyle = .midfoot
        initialState.condition.sleepHours = "8"
        initialState.selectedDifficultyLevel = .medium
        
        enum TestError: Error, LocalizedError {
            case saveFailed
            var errorDescription: String? { "Save failed" }
        }
        
        let store = TestStore(initialState: initialState) {
            AddRecordFeature()
        } withDependencies: {
            $0.weatherClient.fetchWeather = { _, _ in
                WeatherData(temperature: 20.0, humidity: 55, windSpeed: 2.5)
            }
            $0.runningRecordClient.save = { _ in
                throw TestError.saveFailed
            }
        }
        
        await store.send(.saveRecord) {
            $0.isLoading = true
            $0.errorMassage = nil
        }
        
        await store.receive(\.recordSaveFailed) {
            $0.isLoading = false
            $0.errorMassage = "Save failed"
        }
    }
    
    // MARK: - Form Validation Tests
    
    @Test("폼 유효성 검사: 모든 필수 값이 있을 때 유효함")
    func formValidWhenAllRequiredFieldsPresent() async {
        let testDate = Date.now
        let healthKitData = HealthKitData(
            distance: 5.0,
            duration: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            routeData: nil,
            startDate: testDate,
            endDate: testDate.addingTimeInterval(1800)
        )
        
        var state = AddRecordFeature.State(healthKitData: healthKitData)
        state.condition.selectedShoe = ShoeModel(name: "Nike Pegasus 40", brand: "Nike")
        state.condition.selectedRunningStyle = .midfoot
        state.condition.sleepHours = "8"
        state.selectedDifficultyLevel = .medium
        
        #expect(state.isFormValid == true)
    }
    
    @Test("폼 유효성 검사: HealthKit 데이터가 없으면 무효함")
    func formInvalidWhenHealthKitDataMissing() async {
        var state = AddRecordFeature.State()
        state.condition.selectedShoe = ShoeModel(name: "Nike Pegasus 40", brand: "Nike")
        state.condition.selectedRunningStyle = .midfoot
        state.condition.sleepHours = "8"
        state.selectedDifficultyLevel = .medium
        
        #expect(state.isFormValid == false)
    }
    
    @Test("폼 유효성 검사: 신발이 선택되지 않으면 무효함")
    func formInvalidWhenShoeNotSelected() async {
        let testDate = Date.now
        let healthKitData = HealthKitData(
            distance: 5.0,
            duration: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            routeData: nil,
            startDate: testDate,
            endDate: testDate.addingTimeInterval(1800)
        )
        
        var state = AddRecordFeature.State(healthKitData: healthKitData)
        state.condition.selectedRunningStyle = .midfoot
        state.condition.sleepHours = "8"
        state.selectedDifficultyLevel = .medium
        
        #expect(state.isFormValid == false)
    }
    
    @Test("폼 유효성 검사: 러닝 스타일이 선택되지 않으면 무효함")
    func formInvalidWhenRunningStyleNotSelected() async {
        let testDate = Date.now
        let healthKitData = HealthKitData(
            distance: 5.0,
            duration: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            routeData: nil,
            startDate: testDate,
            endDate: testDate.addingTimeInterval(1800)
        )
        
        var state = AddRecordFeature.State(healthKitData: healthKitData)
        state.condition.selectedShoe = ShoeModel(name: "Nike Pegasus 40", brand: "Nike")
        state.condition.sleepHours = "8"
        state.selectedDifficultyLevel = .medium
        
        #expect(state.isFormValid == false)
    }
    
    @Test("폼 유효성 검사: 수면 시간이 유효하지 않으면 무효함")
    func formInvalidWhenSleepHoursInvalid() async {
        let testDate = Date.now
        let healthKitData = HealthKitData(
            distance: 5.0,
            duration: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            routeData: nil,
            startDate: testDate,
            endDate: testDate.addingTimeInterval(1800)
        )
        
        var state = AddRecordFeature.State(healthKitData: healthKitData)
        state.condition.selectedShoe = ShoeModel(name: "Nike Pegasus 40", brand: "Nike")
        state.condition.selectedRunningStyle = .midfoot
        state.condition.sleepHours = "25"  // Invalid: > 24
        state.selectedDifficultyLevel = .medium
        
        #expect(state.isFormValid == false)
    }
    
    @Test("폼 유효성 검사: 난이도가 선택되지 않으면 무효함")
    func formInvalidWhenDifficultyNotSelected() async {
        let testDate = Date.now
        let healthKitData = HealthKitData(
            distance: 5.0,
            duration: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            routeData: nil,
            startDate: testDate,
            endDate: testDate.addingTimeInterval(1800)
        )
        
        var state = AddRecordFeature.State(healthKitData: healthKitData)
        state.condition.selectedShoe = ShoeModel(name: "Nike Pegasus 40", brand: "Nike")
        state.condition.selectedRunningStyle = .midfoot
        state.condition.sleepHours = "8"
        
        #expect(state.isFormValid == false)
    }
}
