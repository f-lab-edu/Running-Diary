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

        // MARK: - Child Features
        var healthKitData: HealthKitDataFeature.State
        var condition: RunningConditionFeature.State

        // MARK: - Additional Data
        var weather: Weather?

        // MARK: - UI State
        var isLoading: Bool = false
        var errorMessage: String?
        var showAuthorizationDeniedAlert: Bool = false
        var showSatisfactionAlert: Bool = false
        var selectedSatisfaction: Int?

        init(mode: RecordMode, date: Date, existingRecord: RunningRecord? = nil) {
            self.mode = mode
            self.date = date
            self.existingRecord = existingRecord
            self.healthKitData = HealthKitDataFeature.State()
            self.condition = RunningConditionFeature.State()
        }
    }

    enum Action {
        case onAppear
        case healthKitData(HealthKitDataFeature.Action)
        case condition(RunningConditionFeature.Action)
        case saveRecord
        case weatherFetched(Weather?)
        case recordSaved(RunningRecord)
        case recordSaveFailed(String)
        case setSatisfaction(Int)
        case saveSatisfaction
        case satisfactionSaved(RunningRecord)
        case satisfactionSaveFailed(String)
        case dismissSatisfactionAlert
        case openSettings
        case dismissAuthorizationDeniedAlert
    }

    @Dependency(\.repositoryClient) var repositoryClient
    @Dependency(\.weatherClient) var weatherClient

    var body: some Reducer<State, Action> {
        Scope(state: \.healthKitData, action: \.healthKitData) {
            HealthKitDataFeature()
        }

        Scope(state: \.condition, action: \.condition) {
            RunningConditionFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                if state.mode == .edit, let record = state.existingRecord {
                    // Edit mode: load existing record into child features
                    state.weather = record.weather
                    return .merge(
                        .send(.healthKitData(.loadFromRecord(record))),
                        .send(.condition(.loadFromRecord(record))),
                        .send(.condition(.loadShoes))
                    )
                } else {
                    // Add mode: just load shoes
                    return .send(.condition(.loadShoes))
                }

            case .healthKitData(let healthKitDataAction):
                switch healthKitDataAction{
                case .healthStoreAuthorizationDenied:
                    state.showAuthorizationDeniedAlert = true
                default:
                    break
                }
                return .none

            case .condition:
                // Handled by RunningConditionFeature
                return .none

            case .saveRecord:
                state.isLoading = true
                state.errorMessage = nil

                let location = extractLocationFromRoute(state.healthKitData.routeData)
                let date = state.date
                let healthKitData = state.healthKitData
                let condition = state.condition
                let existingRecordId = state.existingRecord?.id
                let mode = state.mode

                return .run { send in
                    do {
                        // Fetch weather
                        let weather = try? await weatherClient.fetchWeather(date, location)
                        await send(.weatherFetched(weather))

                        // Create record
                        let record = RunningRecord(
                            id: existingRecordId ?? UUID(),
                            date: date,
                            distanceInKilometers: Double(healthKitData.distance),
                            durationInSeconds: parseDuration(healthKitData.duration),
                            averagePace: healthKitData.averagePace.isEmpty ? nil : healthKitData.averagePace,
                            averageHeartRate: Int(healthKitData.averageHeartRate),
                            averageCadence: Int(healthKitData.averageCadence),
                            painAreas: Array(condition.selectedPainAreas),
                            runningStyle: condition.selectedRunningStyle,
                            condition: RunningCondition(
                                sleep: Int(condition.sleepHours),
                                meal: condition.hadMeal,
                                alcohol: condition.hadAlcohol,
                                memo: condition.memo.isEmpty ? nil : condition.memo
                            ),
                            shoes: condition.selectedShoe,
                            weather: weather,
                            satisfaction: nil,
                            routeData: healthKitData.routeData,
                            hasMap: healthKitData.routeData != nil
                        )

                        // Save or update
                        if mode == .add {
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
                let date = state.date
                let healthKitData = state.healthKitData
                let condition = state.condition
                let existingRecordId = state.existingRecord?.id
                let weather = state.weather

                return .run { send in
                    do {
                        let record = RunningRecord(
                            id: existingRecordId ?? UUID(),
                            date: date,
                            distanceInKilometers: Double(healthKitData.distance),
                            durationInSeconds: parseDuration(healthKitData.duration),
                            averagePace: healthKitData.averagePace.isEmpty ? nil : healthKitData.averagePace,
                            averageHeartRate: Int(healthKitData.averageHeartRate),
                            averageCadence: Int(healthKitData.averageCadence),
                            painAreas: Array(condition.selectedPainAreas),
                            runningStyle: condition.selectedRunningStyle,
                            condition: RunningCondition(
                                sleep: Int(condition.sleepHours),
                                meal: condition.hadMeal,
                                alcohol: condition.hadAlcohol,
                                memo: condition.memo.isEmpty ? nil : condition.memo
                            ),
                            shoes: condition.selectedShoe,
                            weather: weather,
                            satisfaction: satisfaction,
                            routeData: healthKitData.routeData,
                            hasMap: healthKitData.routeData != nil
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

            case .dismissSatisfactionAlert:
                state.showSatisfactionAlert = false
                return .none

            case .openSettings:
                URLOpener.openSettings()
                return .none

            case .dismissAuthorizationDeniedAlert:
                state.showAuthorizationDeniedAlert = false
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

    private func parseDuration(_ durationString: String) -> TimeInterval? {
        guard !durationString.isEmpty else { return nil }

        let components = durationString.split(separator: ":").compactMap { Int($0) }

        if components.count == 2 {
            // MM:SS format
            let minutes = components[0]
            let seconds = components[1]
            return TimeInterval(minutes * 60 + seconds)
        } else if components.count == 3 {
            // HH:MM:SS format
            let hours = components[0]
            let minutes = components[1]
            let seconds = components[2]
            return TimeInterval(hours * 3600 + minutes * 60 + seconds)
        }

        return nil
    }
}

private struct CoordinateData: Codable {
    let latitude: Double
    let longitude: Double
}
