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
            $0.healthKitClient.ensureAuthorizationIfNeeded = {}
            $0.healthKitClient.fetchRunningData = { _ in nil }
        }

        await store.send(.onAppear)

        await store.receive(\.healthKitData.loadData) {
            $0.healthKitData.isLoading = true
            $0.healthKitData.errorMessage = nil
        }

        await store.receive(\.condition.loadShoes) {
            $0.condition.isLoadingShoes = true
        }

        await store.receive(\.condition.shoesLoaded) {
            $0.condition.isLoadingShoes = false
            $0.condition.shoes = mockShoes
        }

        await store.receive(\.healthKitData.dataLoadFailed) {
            $0.healthKitData.isLoading = false
            $0.healthKitData.errorMessage = "\(L10n.Healthkit.Error.fetchContext): \(L10n.Healthkit.Error.dataNotFound)"
            $0.healthKitData.isDataLoaded = false
            $0.emptyHealthKitDataAlert = AlertState {
                TextState("피트니스 데이터 가져오기 실패")
            } actions: {
                ButtonState(action: .goBack) {
                    TextState("뒤로 가기")
                }
            } message: {
                TextState(L10n.Healthkit.Error.dataNotFound)
            }
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
            difficultyLevel: .hard
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
            $0.selectedDifficultyLevel = .hard
        }

        await store.receive(\.healthKitData.loadFromRecord) {
            $0.healthKitData.data = HealthKitDataModel(
                distance: 5.2,
                durationInSeconds: 1800,
                averagePace: "5'30\"",
                averageHeartRate: 155,
                averageCadence: 180,
                routeData: nil
            )
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

    @Test("기록 저장 성공 시 날씨 조회")
    func saveRecordSuccessFetchesWeather() async {
        let testDate = Date()
        let mockWeather = Weather(temperature: 20.0, humidity: 55, windSpeed: 2.5)
        var savedRecord: RunningRecord?

        var initialState = AddRecordFeature.State(date: testDate)
        initialState.healthKitData.data = HealthKitDataModel(
            distance: 5.0,
            durationInSeconds: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            routeData: nil
        )
        initialState.condition.selectedShoe = "Nike Pegasus 40"
        initialState.condition.selectedRunningStyle = .midfoot
        initialState.condition.sleepHours = "8"
        initialState.condition.hadMeal = true
        initialState.selectedDifficultyLevel = .medium

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
            durationInSeconds: 1500,
            averagePace: "5'00\"",
            averageHeartRate: 145,
            averageCadence: 165,
            runningStyle: .midfoot,
            condition: RunningCondition(meal: false, alcohol: false)
        )

        let mockWeather = Weather(temperature: 18.0, humidity: 65, windSpeed: 1.5)
        var updatedRecord: RunningRecord?

        var initialState = AddRecordFeature.State(
            date: testDate,
            existingRecord: existingRecord
        )
        initialState.healthKitData.data = HealthKitDataModel(
            distance: 5.5,
            durationInSeconds: 2100,
            averagePace: "6'20\"",
            averageHeartRate: 150,
            averageCadence: 170,
            routeData: nil
        )
        initialState.condition.selectedShoe = "Nike Pegasus 40"
        initialState.condition.selectedRunningStyle = .forefoot
        initialState.condition.sleepHours = "7"
        initialState.selectedDifficultyLevel = .hard

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
            $0.errorMessage = nil
        }

        await store.receive(\.weatherFetched) {
            $0.weather = mockWeather
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
        var initialState = AddRecordFeature.State(date: Date())
        initialState.healthKitData.data = HealthKitDataModel(
            distance: 5.0,
            durationInSeconds: 1800,
            averagePace: "6'00\"",
            averageHeartRate: 150,
            averageCadence: 170,
            routeData: nil
        )
        initialState.condition.selectedShoe = "Nike Pegasus 40"
        initialState.condition.selectedRunningStyle = .midfoot
        initialState.condition.sleepHours = "8"
        initialState.selectedDifficultyLevel = .medium

        let store = TestStore(initialState: initialState) {
            AddRecordFeature()
        } withDependencies: {
            $0.weatherClient.fetchWeather = { _, _ in
                throw WeatherError.networkError
            }
            $0.repositoryClient.save = { _ in
                throw RepositoryError.saveFailed
            }
        }

        await store.send(.saveRecord) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.weatherFetched)

        await store.receive(\.recordSaveFailed) {
            $0.isLoading = false
            $0.errorMessage = "\(L10n.Record.Error.saveContext): \(L10n.Repository.Error.saveFailed)"
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
            $0.authorizationAlert = AlertState {
                TextState("건강 데이터 접근 거부됨")
            } actions: {
                ButtonState(action: .openSettings) {
                    TextState("설정으로 이동")
                }
                ButtonState(action: .goBack) {
                    TextState("뒤로 가기")
                }
            } message: {
                TextState("러닝 데이터를 가져오기 위해 설정에서 접근을 허용해주세요.")
            }
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
            ButtonState(action: .goBack) {
                TextState("뒤로 가기")
            }
        }

        let store = TestStore(initialState: initialState) {
            AddRecordFeature()
        }

        await store.send(.authorizationAlert(.dismiss)) {
            $0.authorizationAlert = nil
        }
    }

    @Test("권한 거부 alert에서 뒤로 가기")
    func goBackFromAuthorizationDeniedAlert() async {
        let store = TestStore(
            initialState: AddRecordFeature.State(date: Date())
        ) {
            AddRecordFeature()
        }

        await store.send(.healthKitData(.healthStoreAuthorizationDenied)) {
            $0.authorizationAlert = AlertState {
                TextState("건강 데이터 접근 거부됨")
            } actions: {
                ButtonState(action: .openSettings) {
                    TextState("설정으로 이동")
                }
                ButtonState(action: .goBack) {
                    TextState("뒤로 가기")
                }
            } message: {
                TextState("러닝 데이터를 가져오기 위해 설정에서 접근을 허용해주세요.")
            }
        }

        await store.send(.authorizationAlert(.presented(.goBack))) {
            $0.authorizationAlert = nil
        }
    }
}
