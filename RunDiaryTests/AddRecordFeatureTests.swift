//
//  AddRecordFeatureTests.swift
//  RunDiaryTests
//
//  Created by Claude on 10/23/25.
//

import Testing
import ComposableArchitecture
import Foundation
@testable import RunDiary

@Suite("AddRecord Feature")
struct AddRecordFeatureTests {

    // MARK: - Initialization Tests

    @Test("Add mode 초기화 시 신발 목록 로드")
    func onAppearInAddModeLoadsShoes() async {
        let testDate = Date()
        let mockShoes = [
            ShoeModel(name: "Nike Pegasus 40", brand: "Nike"),
            ShoeModel(name: "Adidas Ultraboost", brand: "Adidas")
        ]

        let store = TestStore(
            initialState: AddRecordFeature.State(date: testDate)
        ) {
            AddRecordFeature()
        } withDependencies: {
            $0.shoeClient.fetchShoes = { mockShoes }
        }

        await store.send(.onAppear)

        await store.receive(\.condition.loadShoes) {
            $0.condition.isLoadingShoes = true
        }

        await store.receive(\.condition.shoesLoaded) {
            $0.condition.isLoadingShoes = false
            $0.condition.shoes = mockShoes
        }
    }

    @Test("Edit mode 초기화 시 기존 기록 로드 및 신발 목록 로드")
    func onAppearInEditModeLoadsExistingRecord() async {
        let testDate = Date()
        let existingRecord = RunningRecord(
            date: testDate,
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
            shoes: "Nike Pegasus 40",
            weather: Weather(temperature: 18.5, humidity: 60, windSpeed: 2.3),
            satisfaction: 4
        )

        let mockShoes = [ShoeModel(name: "Nike Pegasus 40", brand: "Nike")]

        let store = TestStore(
            initialState: AddRecordFeature.State(
                date: testDate,
                existingRecord: existingRecord
            )
        ) {
            AddRecordFeature()
        } withDependencies: {
            $0.shoeClient.fetchShoes = { mockShoes }
        }

        await store.send(.onAppear) {
            $0.weather = existingRecord.weather
        }

        await store.receive(\.healthKitData.loadFromRecord) {
            $0.healthKitData.distance = 5.2
            $0.healthKitData.duration = "30:00"
            $0.healthKitData.averagePace = "5'30\""
            $0.healthKitData.averageHeartRate = 155
            $0.healthKitData.averageCadence = 180
            $0.healthKitData.isDataLoaded = true
        }

        await store.receive(\.condition.loadFromRecord) {
            $0.condition.selectedPainAreas = [.knee]
            $0.condition.selectedRunningStyle = .midfoot
            $0.condition.sleepHours = "7"
            $0.condition.hadMeal = true
            $0.condition.hadAlcohol = false
            $0.condition.memo = "좋은 컨디션"
            $0.condition.selectedShoe = "Nike Pegasus 40"
        }

        await store.receive(\.condition.loadShoes) {
            $0.condition.isLoadingShoes = true
        }

        await store.receive(\.condition.shoesLoaded) {
            $0.condition.isLoadingShoes = false
            $0.condition.shoes = mockShoes
        }
    }

    // MARK: - Save Record Tests

    @Test("기록 저장 성공 시 날씨 조회 및 만족도 alert 표시")
    func saveRecordSuccessShowsSatisfactionAlert() async {
        let testDate = Date()
        let mockWeather = Weather(temperature: 20.0, humidity: 55, windSpeed: 2.5)
        var savedRecord: RunningRecord?

        var initialState = AddRecordFeature.State(date: testDate)
        initialState.healthKitData.distance = 5.0
        initialState.healthKitData.duration = "30:00"
        initialState.condition.hadMeal = true

        let store = TestStore(initialState: initialState) {
            AddRecordFeature()
        } withDependencies: {
            $0.weatherClient.fetchWeather = { _, _ in mockWeather }
            $0.repositoryClient.save = { record in
                savedRecord = record
            }
        }

        await store.send(.saveRecord) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.weatherFetched) {
            $0.weather = mockWeather
        }

        await store.receive(\.recordSaved) {
            $0.isLoading = false
            // satisfactionDialog is presented
            #expect($0.satisfactionDialog != nil)
        }

        #expect(savedRecord != nil)
        #expect(savedRecord?.weather?.temperature == 20.0)
    }

    @Test("Edit mode에서 기록 업데이트")
    func saveRecordInEditModeUpdatesRecord() async {
        let testDate = Date()
        let recordId = UUID()
        let existingRecord = RunningRecord(
            id: recordId,
            date: testDate,
            distanceInKilometers: 3.0,
            condition: RunningCondition(meal: false, alcohol: false)
        )

        let mockWeather = Weather(temperature: 18.0, humidity: 65, windSpeed: 1.5)
        var updatedRecord: RunningRecord?

        var initialState = AddRecordFeature.State(
            date: testDate,
            existingRecord: existingRecord
        )
        initialState.healthKitData.distance = 5.5
        initialState.healthKitData.duration = "35:00"

        let store = TestStore(initialState: initialState) {
            AddRecordFeature()
        } withDependencies: {
            $0.weatherClient.fetchWeather = { _, _ in mockWeather }
            $0.repositoryClient.update = { record in
                updatedRecord = record
            }
        }

        await store.send(.saveRecord) {
            $0.isLoading = true
        }

        await store.receive(\.weatherFetched) {
            $0.weather = mockWeather
        }

        await store.receive(\.recordSaved) {
            $0.isLoading = false
            // satisfactionDialog is presented
            #expect($0.satisfactionDialog != nil)
        }

        #expect(updatedRecord != nil)
        #expect(updatedRecord?.id == recordId)
        #expect(updatedRecord?.distanceInKilometers == 5.5)
    }

    @Test("기록 저장 실패 시 에러 메시지 표시")
    func saveRecordFailureShowsError() async {
        struct SaveError: Error, LocalizedError {
            var errorDescription: String? { "저장 실패" }
        }

        let store = TestStore(
            initialState: AddRecordFeature.State(date: Date())
        ) {
            AddRecordFeature()
        } withDependencies: {
            $0.weatherClient.fetchWeather = { _, _ in
                throw SaveError()
            }
        }

        await store.send(.saveRecord) {
            $0.isLoading = true
        }

        await store.receive(\.recordSaveFailed) {
            $0.isLoading = false
            $0.errorMessage = "기록 저장에 실패했습니다: 저장 실패"
        }
    }

    // MARK: - Satisfaction Tests

    @Test("만족도 선택 및 저장")
    func setSatisfactionAndSave() async {
        let testDate = Date()
        let recordId = UUID()
        let existingRecord = RunningRecord(
            id: recordId,
            date: testDate,
            distanceInKilometers: 5.0,
            condition: RunningCondition(meal: true, alcohol: false)
        )

        var updatedRecord: RunningRecord?

        var initialState = AddRecordFeature.State(
            date: testDate,
            existingRecord: existingRecord
        )
        initialState.healthKitData.distance = 5.0
        initialState.healthKitData.duration = "30:00"

        let store = TestStore(initialState: initialState) {
            AddRecordFeature()
        } withDependencies: {
            $0.repositoryClient.update = { record in
                updatedRecord = record
            }
        }

        await store.send(.setSatisfaction(4)) {
            $0.selectedSatisfaction = 4
        }

        await store.send(.saveSatisfaction) {
            $0.isLoading = true
        }

        await store.receive(\.satisfactionSaved) {
            $0.isLoading = false
            $0.existingRecord = updatedRecord
        }

        #expect(updatedRecord != nil)
        #expect(updatedRecord?.satisfaction == 4)
    }

    @Test("만족도 저장 실패 시 에러 메시지 표시")
    func saveSatisfactionFailureShowsError() async {
        struct SatisfactionError: Error, LocalizedError {
            var errorDescription: String? { "만족도 저장 실패" }
        }

        let store = TestStore(
            initialState: AddRecordFeature.State(date: Date())
        ) {
            AddRecordFeature()
        } withDependencies: {
            $0.repositoryClient.update = { _ in
                throw SatisfactionError()
            }
        }

        await store.send(.setSatisfaction(3)) {
            $0.selectedSatisfaction = 3
        }

        await store.send(.saveSatisfaction) {
            $0.isLoading = true
        }

        await store.receive(\.satisfactionSaveFailed) {
            $0.isLoading = false
            $0.errorMessage = "만족도 저장에 실패했습니다: 만족도 저장 실패"
        }
    }

    // MARK: - Alert Tests

    @Test("HealthKit 권한 거부 시 alert 표시")
    func healthKitAuthorizationDeniedShowsAlert() async {
        let store = TestStore(
            initialState: AddRecordFeature.State(date: Date())
        ) {
            AddRecordFeature()
        }

        await store.send(.healthKitData(.healthStoreAuthorizationDenied)) {
            // authorizationAlert is presented
            #expect($0.authorizationAlert != nil)
        }
    }

    @Test("만족도 dialog 닫기")
    func dismissSatisfactionDialog() async {
        var initialState = AddRecordFeature.State(date: Date())
        initialState.satisfactionDialog = ConfirmationDialogState {
            TextState("러닝 만족도")
        } actions: {
            ButtonState(action: .rate(3)) {
                TextState("3점")
            }
        }

        let store = TestStore(initialState: initialState) {
            AddRecordFeature()
        }

        await store.send(.satisfactionDialog(.dismiss)) {
            $0.satisfactionDialog = nil
        }
    }

    @Test("권한 거부 alert 닫기")
    func dismissAuthorizationDeniedAlert() async {
        var initialState = AddRecordFeature.State(date: Date())
        initialState.authorizationAlert = AlertState {
            TextState("건강 데이터 접근 거부됨")
        } actions: {
            ButtonState(action: .openSettings) {
                TextState("설정으로 이동")
            }
        }

        let store = TestStore(initialState: initialState) {
            AddRecordFeature()
        }

        await store.send(.authorizationAlert(.dismiss)) {
            $0.authorizationAlert = nil
        }
    }
}
