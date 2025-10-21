//
//  AddRecordFeatureTests.swift
//  RunDiaryTests
//
//  Created by Claude on 10/21/25.
//

import Testing
import ComposableArchitecture
import Foundation
import CoreLocation
@testable import RunDiary

@Suite("AddRecord Feature")
struct AddRecordFeatureTests {

    @Test("추가 모드 시작 시 빈 상태 초기화")
    func addModeStartsWithEmptyState() async {
        let testDate = Date()
        let mockShoes = [
            ShoeModel(name: "Nike Pegasus 40", brand: "Nike"),
            ShoeModel(name: "Adidas Ultraboost 22", brand: "Adidas")
        ]

        let store = TestStore(
            initialState: AddRecordFeature.State(mode: .add, date: testDate)
        ) {
            AddRecordFeature()
        } withDependencies: {
            $0.shoeClient.fetchShoes = { mockShoes }
        }

        await store.send(.onAppear)

        await store.receive(\.loadShoes)

        await store.receive(\.shoesLoaded) {
            $0.shoes = mockShoes
            $0.errorMessage = nil
        }
    }

    @Test("편집 모드 시작 시 기존 기록 로드")
    func editModeLoadsExistingRecord() async {
        let testDate = Date()
        let existingRecord = RunningRecord(
            date: testDate,
            distanceInKilometers: 5.0,
            averagePace: "5:30",
            averageHeartRate: 150,
            averageCadence: 180,
            painAreas: ["무릎", "발목"],
            runningStyle: "포어풋",
            condition: RunningCondition(
                sleep: 7,
                meal: true,
                alcohol: false,
                memo: "좋은 컨디션"
            ),
            shoes: "Nike Pegasus 40",
            weather: Weather(temperature: 20, humidity: 50, windSpeed: 2.5)
        )
        let mockShoes = [ShoeModel(name: "Nike Pegasus 40", brand: "Nike")]

        let store = TestStore(
            initialState: AddRecordFeature.State(
                mode: .edit,
                date: testDate,
                existingRecord: existingRecord
            )
        ) {
            AddRecordFeature()
        } withDependencies: {
            $0.shoeClient.fetchShoes = { mockShoes }
        }

        await store.send(.onAppear) {
            // 기존 기록 데이터가 로드되어야 함
            $0.distance = "5.00"
            $0.averagePace = "5:30"
            $0.averageHeartRate = "150"
            $0.averageCadence = "180"
            $0.selectedPainAreas = Set(["무릎", "발목"])
            $0.selectedRunningStyle = "포어풋"
            $0.sleepHours = "7"
            $0.hadMeal = true
            $0.hadAlcohol = false
            $0.memo = "좋은 컨디션"
            $0.selectedShoe = "Nike Pegasus 40"
            $0.weather = Weather(temperature: 20, humidity: 50, windSpeed: 2.5)
            $0.isHealthKitDataLoaded = true
        }

        await store.receive(\.loadShoes)

        await store.receive(\.shoesLoaded) {
            $0.shoes = mockShoes
            $0.errorMessage = nil
        }
    }

    @Test("신발 목록 조회 성공")
    func shoesFetchSuccess() async {
        let mockShoes = [
            ShoeModel(name: "Nike Pegasus 40", brand: "Nike"),
            ShoeModel(name: "Adidas Ultraboost 22", brand: "Adidas"),
            ShoeModel(name: "Asics Gel-Kayano 29", brand: "Asics"),
            ShoeModel(name: "New Balance 1080v12", brand: "New Balance"),
            ShoeModel(name: "Hoka Clifton 9", brand: "Hoka"),
            ShoeModel(name: "Brooks Ghost 15", brand: "Brooks"),
            ShoeModel(name: "On Cloudstratus 3", brand: "On")
        ]

        let store = TestStore(
            initialState: AddRecordFeature.State(mode: .add, date: Date())
        ) {
            AddRecordFeature()
        } withDependencies: {
            $0.shoeClient.fetchShoes = { mockShoes }
        }

        await store.send(.loadShoes)

        await store.receive(\.shoesLoaded) {
            $0.shoes = mockShoes
            $0.errorMessage = nil
        }
    }

    @Test("신발 조회 실패 시 에러 표시")
    func shoesFetchFailureDisplaysError() async {
        let store = TestStore(
            initialState: AddRecordFeature.State(mode: .add, date: Date())
        ) {
            AddRecordFeature()
        } withDependencies: {
            $0.shoeClient.fetchShoes = { throw ShoeStoreError.fetchFailed }
        }

        await store.send(.loadShoes)

        await store.receive(\.shoesLoadFailed) {
            $0.errorMessage = "신발 목록을 불러올 수 없습니다: \(ShoeStoreError.fetchFailed.localizedDescription)"
        }
    }

    @Test("HealthKit 데이터 로드 성공")
    func healthKitDataLoadSuccess() async {
        let testDate = Date()
        let mockHealthKitData = HealthKitRunningData(
            distance: 5.5,
            averagePace: "5:15",
            averageHeartRate: 155,
            averageCadence: 175,
            routeData: nil
        )

        let store = TestStore(
            initialState: AddRecordFeature.State(mode: .add, date: testDate)
        ) {
            AddRecordFeature()
        } withDependencies: {
            $0.healthKitClient.requestAuthorization = {}
            $0.healthKitClient.fetchRunningData = { _ in mockHealthKitData }
        }

        await store.send(.loadHealthKitData) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.healthKitDataLoaded) {
            $0.isLoading = false
            $0.distance = "5.50"
            $0.averagePace = "5:15"
            $0.averageHeartRate = "155"
            $0.averageCadence = "175"
            $0.routeData = nil
            $0.isHealthKitDataLoaded = true
        }
    }

    @Test("HealthKit 로드 실패 시 에러 표시")
    func healthKitDataLoadFailureDisplaysError() async {
        let testDate = Date()

        let store = TestStore(
            initialState: AddRecordFeature.State(mode: .add, date: testDate)
        ) {
            AddRecordFeature()
        } withDependencies: {
            $0.healthKitClient.requestAuthorization = {}
            $0.healthKitClient.fetchRunningData = { _ in nil }
        }

        await store.send(.loadHealthKitData) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.healthKitDataFailed) {
            $0.isLoading = false
            $0.isHealthKitDataLoaded = false
            $0.errorMessage = "HealthKit 데이터를 가져올 수 없습니다: 데이터를 찾을 수 없습니다"
        }
    }

    @Test("거리 필드 업데이트")
    func distanceFieldUpdate() async {
        let store = TestStore(
            initialState: AddRecordFeature.State(mode: .add, date: Date())
        ) {
            AddRecordFeature()
        }

        await store.send(.updateDistance("10.5")) {
            $0.distance = "10.5"
        }
    }

    @Test("기록 저장 시 날씨 조회 및 만족도 입력창 표시")
    func saveRecordFetchesWeatherAndShowsSatisfactionAlert() async {
        let testDate = Date()
        let mockWeather = Weather(temperature: 22, humidity: 60, windSpeed: 3.5)

        let store = TestStore(
            initialState: AddRecordFeature.State(mode: .add, date: testDate)
        ) {
            AddRecordFeature()
        } withDependencies: {
            $0.weatherClient.fetchWeather = { _, _ in mockWeather }
            $0.repositoryClient.save = { _ in }
        }

        // 필드 설정
        await store.send(.updateDistance("5.0")) {
            $0.distance = "5.0"
        }
        await store.send(.updateAveragePace("6:00")) {
            $0.averagePace = "6:00"
        }
        await store.send(.updateAverageHeartRate("140")) {
            $0.averageHeartRate = "140"
        }
        await store.send(.updateAverageCadence("170")) {
            $0.averageCadence = "170"
        }
        await store.send(.updateSleepHours("8")) {
            $0.sleepHours = "8"
        }
        await store.send(.updateHadMeal(true)) {
            $0.hadMeal = true
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
            $0.showSatisfactionAlert = true
        }
    }

    @Test("만족도 저장 후 입력창 닫기")
    func saveSatisfactionClosesAlert() async {
        let testDate = Date()
        let mockWeather = Weather(temperature: 20, humidity: 55, windSpeed: 2.0)

        var capturedUpdatedRecord: RunningRecord?

        let store = TestStore(
            initialState: AddRecordFeature.State(mode: .add, date: testDate)
        ) {
            AddRecordFeature()
        } withDependencies: {
            $0.repositoryClient.update = { record in
                capturedUpdatedRecord = record
            }
        }

        // 상태 설정
        await store.send(.updateDistance("3.0")) {
            $0.distance = "3.0"
        }
        await store.send(.setSatisfaction(4)) {
            $0.selectedSatisfaction = 4
        }
        await store.send(.weatherFetched(mockWeather)) {
            $0.weather = mockWeather
        }

        await store.send(.saveSatisfaction) {
            $0.isLoading = true
        }

        await store.receive(\.satisfactionSaved) {
            $0.isLoading = false
            $0.showSatisfactionAlert = false
            $0.existingRecord = capturedUpdatedRecord
        }
    }
}
