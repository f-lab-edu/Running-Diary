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

@Suite("AddRecordFeature")
struct AddRecordFeatureTests {

    private let invalidSleepHours = "abc"

    // MARK: - Initialization Tests

    @Test("Add mode: HealthKit 데이터와 함께 초기화")
    func initializeWithHealthKitWorkout() async {
        // Given
        let expectedDistance = 5.2
        let expectedDuration = TimeInterval(1800)
        let expectedMode = RecordMode.add
        let healthKitWorkout = makeHealthKitWorkout(distance: expectedDistance, duration: expectedDuration)

        // When
        let state = AddRecordFeature.State(healthKitWorkout: healthKitWorkout)

        // Then
        #expect(state.mode == expectedMode)
        #expect(state.healthKitWorkout.data?.distance == expectedDistance)
        #expect(state.healthKitWorkout.data?.duration == expectedDuration)
        #expect(state.existingRecord == nil)
        #expect(state.weather == nil)
        #expect(state.selectedDifficultyLevel == nil)
    }

    @Test("Edit mode: 기존 레코드와 함께 초기화")
    func initializeWithExistingRecord() async {
        // Given
        let expectedMode = RecordMode.edit
        let expectedSleepHours = "7"
        let expectedMemo = "좋은 컨디션"
        let existingRecord = makeExistingRecord(
            sleepHours: 7,
            hadMeal: true,
            hadAlcohol: false,
            memo: expectedMemo
        )

        // When
        let state = AddRecordFeature.State(existingRecord: existingRecord)

        // Then
        #expect(state.mode == expectedMode)
        #expect(state.existingRecord != nil)
        #expect(state.condition.sleepHours == expectedSleepHours)
        #expect(state.condition.hadMeal == true)
        #expect(state.condition.hadAlcohol == false)
        #expect(state.condition.memo == expectedMemo)
    }

    @Test("onAppear: Edit mode에서 기존 레코드 데이터 로드")
    func onAppear_editMode_loadsExistingRecordData() async {
        // Given
        let expectedWeather = WeatherData(temperature: 18.5, humidity: 60, windSpeed: 2.3)
        let expectedDifficulty = DifficultyLevel.hard
        let existingRecord = makeExistingRecord(
            weather: expectedWeather,
            difficultyLevel: expectedDifficulty
        )
        let store = TestStore(initialState: AddRecordFeature.State(existingRecord: existingRecord)) {
            AddRecordFeature()
        }

        // When
        await store.send(.onAppear) {
            // Then
            $0.weather = expectedWeather
            $0.selectedDifficultyLevel = expectedDifficulty
        }
    }
    
    // MARK: - Save Record Tests

    @Test("Add mode: 기록 저장 성공")
    func saveRecord_addMode_succeeds() async {
        // Given
        let expectedDistance = 5.0
        let expectedWeather = WeatherData(temperature: 20.0, humidity: 55, windSpeed: 2.5)
        var savedRecord: RunningRecord?

        let healthKitWorkout = makeHealthKitWorkout(distance: expectedDistance)
        var initialState = AddRecordFeature.State(healthKitWorkout: healthKitWorkout)
        initialState.condition.selectedShoe = makeShoeModel()
        initialState.condition.selectedRunningStyle = .midfoot
        initialState.condition.sleepHours = "8"
        initialState.condition.hadMeal = true
        initialState.selectedDifficultyLevel = .medium

        let store = TestStore(initialState: initialState) {
            AddRecordFeature()
        } withDependencies: {
            $0.weatherClient.fetchWeather = { _, _ in expectedWeather }
            $0.runningRecordClient.saveRecord = { record in
                savedRecord = record
            }
            $0.dismiss = DismissEffect { }
        }

        // When
        await store.send(.saveRecord) {
            $0.isLoading = true
            $0.errorMassage = nil
        }

        // Then
        await store.receive(\.recordSaved) {
            $0.isLoading = false
        }

        #expect(savedRecord != nil)
        #expect(savedRecord?.distanceInKilometers == expectedDistance)
    }

    @Test("Edit mode: 기록 업데이트 성공")
    func saveRecord_editMode_updatesRecord() async {
        // Given
        let expectedRecordId = UUID()
        let expectedDistance = 5.5
        let expectedWeather = WeatherData(temperature: 18.0, humidity: 65, windSpeed: 1.5)
        var updatedRecord: RunningRecord?

        let existingRecord = makeExistingRecord(id: expectedRecordId, distance: 3.0)
        let healthKitWorkout = makeHealthKitWorkout(distance: expectedDistance, duration: 2100)

        var initialState = AddRecordFeature.State(
            existingRecord: existingRecord,
            healthKitWorkout: healthKitWorkout
        )
        initialState.condition.selectedShoe = makeShoeModel()
        initialState.condition.selectedRunningStyle = .forefoot
        initialState.condition.sleepHours = "7"
        initialState.selectedDifficultyLevel = .hard

        let store = TestStore(initialState: initialState) {
            AddRecordFeature()
        } withDependencies: {
            $0.weatherClient.fetchWeather = { _, _ in expectedWeather }
            $0.runningRecordClient.updateRecord = { record in
                updatedRecord = record
            }
            $0.dismiss = DismissEffect { }
        }

        // When
        await store.send(.saveRecord) {
            $0.isLoading = true
            $0.errorMassage = nil
        }

        // Then
        await store.receive(\.recordSaved) {
            $0.isLoading = false
        }

        #expect(updatedRecord != nil)
        #expect(updatedRecord?.id == expectedRecordId)
        #expect(updatedRecord?.distanceInKilometers == expectedDistance)
    }

    @Test("기록 저장 실패 시 에러 메시지 표시")
    func saveRecord_failure_showsError() async {
        // Given
        let expectedErrorMessage = "Save failed"
        let expectedWeather = WeatherData(temperature: 20.0, humidity: 55, windSpeed: 2.5)
        let healthKitWorkout = makeHealthKitWorkout()

        var initialState = AddRecordFeature.State(healthKitWorkout: healthKitWorkout)
        initialState.condition.selectedShoe = makeShoeModel()
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
            $0.weatherClient.fetchWeather = { _, _ in expectedWeather }
            $0.runningRecordClient.saveRecord = { _ in
                throw TestError.saveFailed
            }
            $0.dismiss = DismissEffect { }
        }

        // When
        await store.send(.saveRecord) {
            $0.isLoading = true
            $0.errorMassage = nil
        }

        // Then
        await store.receive(\.recordSaveFailed) {
            $0.isLoading = false
            $0.errorMassage = expectedErrorMessage
        }
    }
    
    // MARK: - Form Validation Tests

    @Test("폼 유효성 검사: 모든 필수 값이 있을 때 유효함")
    func formValid_allRequiredFieldsPresent() async {
        // Given
        let expectedIsValid = true
        let healthKitWorkout = makeHealthKitWorkout()

        var state = AddRecordFeature.State(healthKitWorkout: healthKitWorkout)
        state.condition.selectedShoe = makeShoeModel()
        state.condition.selectedRunningStyle = .midfoot
        state.condition.sleepHours = "8"
        state.selectedDifficultyLevel = .medium

        // When & Then
        #expect(state.isFormValid == expectedIsValid)
    }

    @Test("폼 유효성 검사: HealthKit 데이터가 없으면 무효함")
    func formInvalid_healthKitWorkoutMissing() async {
        // Given
        let expectedIsValid = false

        var state = AddRecordFeature.State()
        state.condition.selectedShoe = makeShoeModel()
        state.condition.selectedRunningStyle = .midfoot
        state.condition.sleepHours = "8"
        state.selectedDifficultyLevel = .medium

        // When & Then
        #expect(state.isFormValid == expectedIsValid)
    }

    @Test("폼 유효성 검사: 신발이 선택되지 않으면 무효함")
    func formInvalid_shoeNotSelected() async {
        // Given
        let expectedIsValid = false
        let healthKitWorkout = makeHealthKitWorkout()

        var state = AddRecordFeature.State(healthKitWorkout: healthKitWorkout)
        state.condition.selectedRunningStyle = .midfoot
        state.condition.sleepHours = "8"
        state.selectedDifficultyLevel = .medium

        // When & Then
        #expect(state.isFormValid == expectedIsValid)
    }

    @Test("폼 유효성 검사: 러닝 스타일이 선택되지 않으면 무효함")
    func formInvalid_runningStyleNotSelected() async {
        // Given
        let expectedIsValid = false
        let healthKitWorkout = makeHealthKitWorkout()

        var state = AddRecordFeature.State(healthKitWorkout: healthKitWorkout)
        state.condition.selectedShoe = makeShoeModel()
        state.condition.sleepHours = "8"
        state.selectedDifficultyLevel = .medium

        // When & Then
        #expect(state.isFormValid == expectedIsValid)
    }

    @Test("폼 유효성 검사: 수면 시간이 유효하지 않으면 무효함")
    func formInvalid_sleepHoursInvalid() async {
        // Given
        let expectedIsValid = false
        let healthKitWorkout = makeHealthKitWorkout()

        var state = AddRecordFeature.State(healthKitWorkout: healthKitWorkout)
        state.condition.selectedShoe = makeShoeModel()
        state.condition.selectedRunningStyle = .midfoot
        state.condition.sleepHours = invalidSleepHours
        state.selectedDifficultyLevel = .medium

        // When & Then
        #expect(state.isFormValid == expectedIsValid)
    }

    @Test("폼 유효성 검사: 난이도가 선택되지 않으면 무효함")
    func formInvalid_difficultyNotSelected() async {
        // Given
        let expectedIsValid = false
        let healthKitWorkout = makeHealthKitWorkout()

        var state = AddRecordFeature.State(healthKitWorkout: healthKitWorkout)
        state.condition.selectedShoe = makeShoeModel()
        state.condition.selectedRunningStyle = .midfoot
        state.condition.sleepHours = "8"

        // When & Then
        #expect(state.isFormValid == expectedIsValid)
    }
}

// MARK: - Test Helpers

private extension AddRecordFeatureTests {

    func makeHealthKitWorkout(
        distance: Double = 5.0,
        duration: TimeInterval = 1800,
        averagePace: String = "6'00\"",
        averageHeartRate: Int = 150,
        averageCadence: Int = 170,
        activeEnergyBurned: Double = 300,
        runningVerticalOscillation: Double = 8,
        runningGroundContactTime: Double = 250,
        walkingStepLength: Double = 1.0,
        routeData: Data? = nil
    ) -> HealthKitWorkout {
        let testDate = Date.now
        return HealthKitWorkout(
            distance: distance,
            duration: duration,
            averagePace: averagePace,
            averageHeartRate: averageHeartRate,
            averageCadence: averageCadence,
            activeEnergyBurned: activeEnergyBurned,
            runningVerticalOscillation: runningVerticalOscillation,
            runningGroundContactTime: runningGroundContactTime,
            walkingStepLength: walkingStepLength,
            routeData: routeData,
            startDate: testDate,
            endDate: testDate.addingTimeInterval(duration)
        )
    }

    func makeExistingRecord(
        id: UUID = UUID(),
        distance: Double = 5.2,
        duration: TimeInterval = 1800,
        sleepHours: Int? = nil,
        hadMeal: Bool = true,
        hadAlcohol: Bool = false,
        memo: String? = nil,
        weather: WeatherData? = nil,
        difficultyLevel: DifficultyLevel? = nil
    ) -> RunningRecord {
        let testDate = Date.now
        return RunningRecord(
            id: id,
            yearMonthDay: YearMonthDay(date: testDate),
            distanceInKilometers: distance,
            durationInSeconds: duration,
            averagePace: "5'30\"",
            averageHeartRate: 155,
            averageCadence: 180,
            painAreas: [.knee],
            runningStyle: .midfoot,
            condition: RunningCondition(
                sleep: sleepHours,
                meal: hadMeal,
                alcohol: hadAlcohol,
                memo: memo
            ),
            shoes: "1",
            weather: weather,
            difficultyLevel: difficultyLevel,
            routeData: nil,
            hasMap: false,
            startTime: testDate,
            endTime: testDate.addingTimeInterval(duration)
        )
    }

    func makeShoeModel(
        name: String = "Nike Pegasus 40",
        brand: String = "Nike"
    ) -> ShoeModel {
        ShoeModel(name: name, brand: brand)
    }
}
