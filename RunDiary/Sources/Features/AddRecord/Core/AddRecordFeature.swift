//
//  AddRecordFeature.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import Foundation
import CoreLocation
import ComposableArchitecture

enum RecordMode {
    case add
    case edit
}

@Reducer
struct AddRecordFeature {
    @ObservableState
    struct State: Equatable {
        // MARK: - Mode
        let mode: RecordMode
        let date: Date
        var existingRecord: RunningRecord?

        // MARK: - HealthKit Data
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

        // MARK: - Data
        var shoes: [ShoeModel] = []
        var weather: Weather?
        var routeData: Data?

        // MARK: - Static Options
        let painAreaOptions = ["무릎", "발목", "종아리", "허벅지", "고관절", "발바닥", "아킬레스건"]
        let runningStyleOptions = ["포어풋", "미드풋", "힐스트라이크", "기타"]

        init(mode: RecordMode, date: Date, existingRecord: RunningRecord? = nil) {
            self.mode = mode
            self.date = date
            self.existingRecord = existingRecord
        }
    }

    enum Action {
        case onAppear
        case loadShoes
        case shoesLoaded([ShoeModel])
        case shoesLoadFailed(String)

        case loadHealthKitData
        case healthKitDataLoaded(HealthKitRunningData)
        case healthKitDataFailed(String)

        // Field updates
        case updateDistance(String)
        case updateAveragePace(String)
        case updateAverageHeartRate(String)
        case updateAverageCadence(String)
        case updateSelectedPainAreas(Set<String>)
        case updateSelectedRunningStyle(String?)
        case updateSleepHours(String)
        case updateHadMeal(Bool)
        case updateHadAlcohol(Bool)
        case updateMemo(String)
        case updateSelectedShoe(String?)

        case saveRecord
        case weatherFetched(Weather)
        case recordSaved(RunningRecord)
        case recordSaveFailed(String)

        case setSatisfaction(Int)
        case saveSatisfaction
        case satisfactionSaved(RunningRecord)
        case satisfactionSaveFailed(String)

        case loadExistingRecord
        case dismissSatisfactionAlert
    }

    @Dependency(\.healthKitClient) var healthKitClient
    @Dependency(\.weatherClient) var weatherClient
    @Dependency(\.repositoryClient) var repositoryClient
    @Dependency(\.shoeClient) var shoeClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if state.mode == .edit, let record = state.existingRecord {
                    // Edit mode: load existing record
                    state.distance = record.distanceInKilometers.map { String(format: "%.2f", $0) } ?? ""
                    state.averagePace = record.averagePace ?? ""
                    state.averageHeartRate = record.averageHeartRate.map { String($0) } ?? ""
                    state.averageCadence = record.averageCadence.map { String($0) } ?? ""
                    state.selectedPainAreas = Set(record.painAreas)
                    state.selectedRunningStyle = record.runningStyle
                    state.sleepHours = record.condition.sleep.map { String($0) } ?? ""
                    state.hadMeal = record.condition.meal
                    state.hadAlcohol = record.condition.alcohol
                    state.memo = record.condition.memo ?? ""
                    state.selectedShoe = record.shoes
                    state.weather = record.weather
                    state.routeData = record.routeData
                    state.isHealthKitDataLoaded = true
                }
                return .send(.loadShoes)

            case .loadShoes:
                return .run { send in
                    do {
                        let shoes = try await shoeClient.fetchAllShoes()
                        await send(.shoesLoaded(shoes))
                    } catch {
                        await send(.shoesLoadFailed(error.localizedDescription))
                    }
                }

            case let .shoesLoaded(shoes):
                state.shoes = shoes
                state.errorMessage = nil
                return .none

            case let .shoesLoadFailed(error):
                state.errorMessage = "신발 목록을 불러올 수 없습니다: \(error)"
                return .none

            case .loadHealthKitData:
                state.isLoading = true
                state.errorMessage = nil

                let date = state.date
                return .run { send in
                    do {
                        try await healthKitClient.requestAuthorization()
                        if let data = try await healthKitClient.fetchRunningData(date) {
                            await send(.healthKitDataLoaded(data))
                        } else {
                            await send(.healthKitDataFailed("데이터를 찾을 수 없습니다"))
                        }
                    } catch {
                        await send(.healthKitDataFailed(error.localizedDescription))
                    }
                }

            case let .healthKitDataLoaded(data):
                state.isLoading = false
                state.distance = data.distance.map { String(format: "%.2f", $0) } ?? ""
                state.averagePace = data.averagePace ?? ""
                state.averageHeartRate = data.averageHeartRate.map { String($0) } ?? ""
                state.averageCadence = data.averageCadence.map { String($0) } ?? ""
                state.routeData = data.routeData
                state.isHealthKitDataLoaded = true
                return .none

            case let .healthKitDataFailed(error):
                state.isLoading = false
                state.errorMessage = "HealthKit 데이터를 가져올 수 없습니다: \(error)"
                state.isHealthKitDataLoaded = false
                return .none

            // Field updates
            case let .updateDistance(value):
                state.distance = value
                return .none

            case let .updateAveragePace(value):
                state.averagePace = value
                return .none

            case let .updateAverageHeartRate(value):
                state.averageHeartRate = value
                return .none

            case let .updateAverageCadence(value):
                state.averageCadence = value
                return .none

            case let .updateSelectedPainAreas(areas):
                state.selectedPainAreas = areas
                return .none

            case let .updateSelectedRunningStyle(style):
                state.selectedRunningStyle = style
                return .none

            case let .updateSleepHours(hours):
                state.sleepHours = hours
                return .none

            case let .updateHadMeal(value):
                state.hadMeal = value
                return .none

            case let .updateHadAlcohol(value):
                state.hadAlcohol = value
                return .none

            case let .updateMemo(text):
                state.memo = text
                return .none

            case let .updateSelectedShoe(shoe):
                state.selectedShoe = shoe
                return .none

            case .saveRecord:
                state.isLoading = true
                state.errorMessage = nil

                let location = extractLocationFromRoute(state.routeData)
                let date = state.date
                let currentState = state

                return .run { send in
                    do {
                        // Fetch weather
                        let weather = try await weatherClient.fetchWeather(date, location)
                        await send(.weatherFetched(weather))

                        // Create record
                        let record = RunningRecord(
                            id: currentState.existingRecord?.id ?? UUID(),
                            date: date,
                            distanceInKilometers: Double(currentState.distance),
                            averagePace: currentState.averagePace.isEmpty ? nil : currentState.averagePace,
                            averageHeartRate: Int(currentState.averageHeartRate),
                            averageCadence: Int(currentState.averageCadence),
                            painAreas: Array(currentState.selectedPainAreas),
                            runningStyle: currentState.selectedRunningStyle,
                            condition: RunningCondition(
                                sleep: Int(currentState.sleepHours),
                                meal: currentState.hadMeal,
                                alcohol: currentState.hadAlcohol,
                                memo: currentState.memo.isEmpty ? nil : currentState.memo
                            ),
                            shoes: currentState.selectedShoe,
                            weather: weather,
                            satisfaction: nil,
                            routeData: currentState.routeData,
                            hasMap: currentState.routeData != nil
                        )

                        // Save or update
                        if currentState.mode == .add {
                            try await repositoryClient.save(record)
                        } else {
                            try await repositoryClient.update(record)
                        }

                        await send(.recordSaved(record))
                    } catch {
                        await send(.recordSaveFailed(error.localizedDescription))
                    }
                }

            case let .weatherFetched(weather):
                state.weather = weather
                return .none

            case .recordSaved:
                state.isLoading = false
                state.showSatisfactionAlert = true
                return .none

            case let .recordSaveFailed(error):
                state.isLoading = false
                state.errorMessage = "기록 저장에 실패했습니다: \(error)"
                return .none

            case let .setSatisfaction(satisfaction):
                state.selectedSatisfaction = satisfaction
                return .none

            case .saveSatisfaction:
                guard let satisfaction = state.selectedSatisfaction else {
                    return .none
                }

                state.isLoading = true
                let currentState = state

                return .run { send in
                    do {
                        let record = RunningRecord(
                            id: currentState.existingRecord?.id ?? UUID(),
                            date: currentState.date,
                            distanceInKilometers: Double(currentState.distance),
                            averagePace: currentState.averagePace.isEmpty ? nil : currentState.averagePace,
                            averageHeartRate: Int(currentState.averageHeartRate),
                            averageCadence: Int(currentState.averageCadence),
                            painAreas: Array(currentState.selectedPainAreas),
                            runningStyle: currentState.selectedRunningStyle,
                            condition: RunningCondition(
                                sleep: Int(currentState.sleepHours),
                                meal: currentState.hadMeal,
                                alcohol: currentState.hadAlcohol,
                                memo: currentState.memo.isEmpty ? nil : currentState.memo
                            ),
                            shoes: currentState.selectedShoe,
                            weather: currentState.weather,
                            satisfaction: satisfaction,
                            routeData: currentState.routeData,
                            hasMap: currentState.routeData != nil
                        )

                        try await repositoryClient.update(record)
                        await send(.satisfactionSaved(record))
                    } catch {
                        await send(.satisfactionSaveFailed(error.localizedDescription))
                    }
                }

            case let .satisfactionSaved(record):
                state.isLoading = false
                state.showSatisfactionAlert = false
                state.existingRecord = record
                return .none

            case let .satisfactionSaveFailed(error):
                state.isLoading = false
                state.errorMessage = "만족도 저장에 실패했습니다: \(error)"
                return .none

            case .loadExistingRecord:
                return .none

            case .dismissSatisfactionAlert:
                state.showSatisfactionAlert = false
                return .none
            }
        }
    }

    private func extractLocationFromRoute(_ routeData: Data?) -> CLLocationCoordinate2D? {
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
