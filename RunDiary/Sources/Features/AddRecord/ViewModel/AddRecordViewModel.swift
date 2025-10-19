//
//  AddRecordViewModel.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Observation
import CoreLocation

enum RecordMode {
    case add
    case edit
}

// MARK: - Protocol

protocol AddRecordViewModelProtocol: Observable {
    var mode: RecordMode { get }
    var distance: String { get set }
    var averagePace: String { get set }
    var averageHeartRate: String { get set }
    var averageCadence: String { get set }
    var isHealthKitDataLoaded: Bool { get }
    var selectedPainAreas: Set<String> { get set }
    var selectedRunningStyle: String? { get set }
    var sleepHours: String { get set }
    var hadMeal: Bool { get set }
    var hadAlcohol: Bool { get set }
    var memo: String { get set }
    var selectedShoe: String? { get set }
    var isLoading: Bool { get }
    var showSatisfactionAlert: Bool { get set }
    var selectedSatisfaction: Int? { get set }
    var shoes: [ShoeModel] { get }
    var painAreaOptions: [String] { get }
    var runningStyleOptions: [String] { get }

    func loadHealthKitData() async
    func saveRecord(onComplete: @escaping (Bool) -> Void) async
    func saveSatisfaction(onComplete: @escaping (Bool) -> Void) async
}

// MARK: - Production Implementation

@Observable
final class AddRecordViewModel: AddRecordViewModelProtocol {
    // MARK: - Mode
    let mode: RecordMode
    let date: Date
    private let existingRecord: RunningRecord?

    // MARK: - Dependencies
    private let healthKitManager: HealthKitManagerProtocol
    private let weatherManager: WeatherManagerProtocol
    private let repository: RunningRecordRepositoryProtocol
    private let shoeManager: ShoeManager

    // MARK: - HealthKit Data (auto/manual)
    var distance: String = ""
    var averagePace: String = ""
    var averageHeartRate: String = ""
    var averageCadence: String = ""
    var isHealthKitDataLoaded: Bool = false

    // MARK: - User Input
    var selectedPainAreas: Set<String> = []
    var selectedRunningStyle: String?
    var sleepHours: String = ""
    var hadMeal: Bool = false
    var hadAlcohol: Bool = false
    var memo: String = ""
    var selectedShoe: String?

    // MARK: - UI State
    var isLoading: Bool = false
    var errorMessage: String?
    var showSatisfactionAlert: Bool = false
    var selectedSatisfaction: Int?
    var shoes: [ShoeModel] = []

    // MARK: - Static Options
    let painAreaOptions = ["무릎", "발목", "종아리", "허벅지", "고관절", "발바닥", "아킬레스건"]
    let runningStyleOptions = ["포어풋", "미드풋", "힐스트라이크", "기타"]

    // MARK: - Weather Data
    private var weather: Weather?
    private var routeData: Data?

    init(
        mode: RecordMode,
        date: Date,
        existingRecord: RunningRecord? = nil,
        healthKitManager: HealthKitManagerProtocol,
        weatherManager: WeatherManagerProtocol,
        repository: RunningRecordRepositoryProtocol,
        shoeManager: ShoeManager
    ) {
        self.mode = mode
        self.date = date
        self.existingRecord = existingRecord
        self.healthKitManager = healthKitManager
        self.weatherManager = weatherManager
        self.repository = repository
        self.shoeManager = shoeManager

        loadShoes()

        if mode == .edit, let record = existingRecord {
            loadExistingRecord(record)
        }
    }

    @MainActor
    func loadHealthKitData() async {
        isLoading = true
        errorMessage = nil

        do {
            // HealthKit 권한 요청
            try await healthKitManager.requestAuthorization()

            // 데이터 가져오기
            if let data = try await healthKitManager.fetchRunningData(for: date) {
                distance = data.distance.map { String(format: "%.2f", $0) } ?? ""
                averagePace = data.averagePace ?? ""
                averageHeartRate = data.averageHeartRate.map { String($0) } ?? ""
                averageCadence = data.averageCadence.map { String($0) } ?? ""
                routeData = data.routeData
                isHealthKitDataLoaded = true
            } else {
                isHealthKitDataLoaded = false
            }
        } catch {
            errorMessage = "HealthKit 데이터를 가져올 수 없습니다: \(error.localizedDescription)"
            isHealthKitDataLoaded = false
        }

        isLoading = false
    }

    @MainActor
    func saveRecord(onComplete: @escaping (Bool) -> Void) async {
        isLoading = true
        errorMessage = nil

        do {
            // 날씨 데이터 가져오기
            let location = extractLocationFromRoute()
            weather = try await weatherManager.fetchWeather(for: date, location: location)

            // RunningRecord 생성
            let record = RunningRecord(
                id: existingRecord?.id ?? UUID(),
                date: date,
                distanceInKilometers: Double(distance),
                averagePace: averagePace.isEmpty ? nil : averagePace,
                averageHeartRate: Int(averageHeartRate),
                averageCadence: Int(averageCadence),
                painAreas: Array(selectedPainAreas),
                runningStyle: selectedRunningStyle,
                condition: RunningCondition(
                    sleep: Int(sleepHours),
                    meal: hadMeal,
                    alcohol: hadAlcohol,
                    memo: memo.isEmpty ? nil : memo
                ),
                shoes: selectedShoe,
                weather: weather,
                satisfaction: nil, // 만족도는 알럿에서 입력
                routeData: routeData,
                hasMap: routeData != nil
            )

            // 저장/수정
            if mode == .add {
                try await repository.save(record)
            } else {
                try await repository.update(record)
            }

            // 만족도 알럿 표시
            showSatisfactionAlert = true

        } catch {
            errorMessage = "기록 저장에 실패했습니다: \(error.localizedDescription)"
            isLoading = false
            onComplete(false)
        }

        isLoading = false
    }

    @MainActor
    func saveSatisfaction(onComplete: @escaping (Bool) -> Void) async {
        guard let satisfaction = selectedSatisfaction else {
            onComplete(true)
            return
        }

        isLoading = true

        do {
            // 만족도 포함하여 업데이트
            let record = RunningRecord(
                id: existingRecord?.id ?? UUID(),
                date: date,
                distanceInKilometers: Double(distance),
                averagePace: averagePace.isEmpty ? nil : averagePace,
                averageHeartRate: Int(averageHeartRate),
                averageCadence: Int(averageCadence),
                painAreas: Array(selectedPainAreas),
                runningStyle: selectedRunningStyle,
                condition: RunningCondition(
                    sleep: Int(sleepHours),
                    meal: hadMeal,
                    alcohol: hadAlcohol,
                    memo: memo.isEmpty ? nil : memo
                ),
                shoes: selectedShoe,
                weather: weather,
                satisfaction: satisfaction,
                routeData: routeData,
                hasMap: routeData != nil
            )

            try await repository.update(record)
            onComplete(true)
        } catch {
            errorMessage = "만족도 저장에 실패했습니다: \(error.localizedDescription)"
            onComplete(false)
        }

        isLoading = false
    }

    private func loadExistingRecord(_ record: RunningRecord) {
        distance = record.distanceInKilometers.map { String(format: "%.2f", $0) } ?? ""
        averagePace = record.averagePace ?? ""
        averageHeartRate = record.averageHeartRate.map { String($0) } ?? ""
        averageCadence = record.averageCadence.map { String($0) } ?? ""
        selectedPainAreas = Set(record.painAreas)
        selectedRunningStyle = record.runningStyle
        sleepHours = record.condition.sleep.map { String($0) } ?? ""
        hadMeal = record.condition.meal
        hadAlcohol = record.condition.alcohol
        memo = record.condition.memo ?? ""
        selectedShoe = record.shoes
        weather = record.weather
        routeData = record.routeData
        isHealthKitDataLoaded = true // 기존 데이터이므로 수정 불가
    }

    private func loadShoes() {
        do {
            shoes = try shoeManager.fetchAllShoes()
        } catch {
            errorMessage = "신발 목록을 불러올 수 없습니다"
        }
    }

    private func extractLocationFromRoute() -> CLLocationCoordinate2D? {
        guard let routeData = routeData else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let coordinates = try decoder.decode([CoordinateData].self, from: routeData)
            guard let first = coordinates.first else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude)
        } catch {
            return nil
        }
    }
}

private struct CoordinateData: Codable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Preview Implementation

@Observable
final class PreviewAddRecordViewModel: AddRecordViewModelProtocol {
    let mode: RecordMode
    var distance: String = "5.20"
    var averagePace: String = "5'30\""
    var averageHeartRate: String = "155"
    var averageCadence: String = "180"
    var isHealthKitDataLoaded: Bool = true
    var selectedPainAreas: Set<String> = ["무릎"]
    var selectedRunningStyle: String? = "포어풋"
    var sleepHours: String = "7"
    var hadMeal: Bool = true
    var hadAlcohol: Bool = false
    var memo: String = "컨디션 좋음"
    var selectedShoe: String? = "Nike Pegasus 40"
    var isLoading: Bool = false
    var showSatisfactionAlert: Bool = false
    var selectedSatisfaction: Int?
    var shoes: [ShoeModel] = []
    let painAreaOptions = ["무릎", "발목", "종아리", "허벅지", "고관절", "발바닥", "아킬레스건"]
    let runningStyleOptions = ["포어풋", "미드풋", "힐스트라이크", "기타"]

    init(mode: RecordMode = .add) {
        self.mode = mode
        setupMockShoes()
    }

    private func setupMockShoes() {
        shoes = [
            ShoeModel(name: "Nike Pegasus 40", brand: "Nike", createdAt: Date()),
            ShoeModel(name: "Adidas Ultraboost 23", brand: "Adidas", createdAt: Date()),
            ShoeModel(name: "Asics Gel-Kayano 30", brand: "Asics", createdAt: Date())
        ]
    }

    @MainActor
    func loadHealthKitData() async {
        // 프리뷰에서는 이미 데이터가 로드되어 있음
    }

    @MainActor
    func saveRecord(onComplete: @escaping (Bool) -> Void) async {
        // 프리뷰에서는 저장하지 않음
        onComplete(true)
    }

    @MainActor
    func saveSatisfaction(onComplete: @escaping (Bool) -> Void) async {
        // 프리뷰에서는 저장하지 않음
        onComplete(true)
    }
}
