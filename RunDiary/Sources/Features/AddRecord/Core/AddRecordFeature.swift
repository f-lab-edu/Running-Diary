//
//  AddRecordFeature.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import ComposableArchitecture
import CoreLocation
import Foundation
import Models

nonisolated enum RecordMode: Equatable {
    case add
    case edit
}

@Reducer
struct AddRecordFeature {
    @ObservableState
    struct State: Equatable {
        var mode: RecordMode {
            guard existingRecord == nil else { return .edit }
            return healthKitWorkout.data != nil ? .add : .edit
        }

        var existingRecord: RunningRecord?
        var healthKitWorkout: HealthKitWorkoutFeature.State
        var condition: RunningConditionFeature.State
        var selectedDifficultyLevel: DifficultyLevel?

        var weather: WeatherData?

        var isLoading: Bool = false
        var errorMassage: String?

        var isFormValid: Bool {
            guard healthKitWorkout.data != nil else { return false }
            guard condition.selectedShoe != nil else { return false }
            guard condition.selectedRunningStyle != nil else { return false }
            guard !condition.sleepHours.isEmpty,
                  let sleepHoursValue = Int(condition.sleepHours),
                  sleepHoursValue >= 1 && sleepHoursValue <= 24
            else { return false }
            guard selectedDifficultyLevel != nil else { return false }
            return true
        }

        init(
            existingRecord: RunningRecord? = nil,
            healthKitWorkout: HealthKitWorkout? = nil
        ) {
            self.existingRecord = existingRecord
            self.healthKitWorkout = HealthKitWorkoutFeature.State(data: healthKitWorkout)
            self.condition = RunningConditionFeature.State(existingRecord: existingRecord)
        }
    }

    enum Action {
        case onAppear
        case healthKitWorkout(HealthKitWorkoutFeature.Action)
        case condition(RunningConditionFeature.Action)
        case updateSelectedDifficultyLevel(DifficultyLevel?)
        case saveRecord
        case weatherFetched(WeatherData?)
        case recordSaved
        case recordSaveFailed(String)
    }

    @Dependency(\.runningRecordClient) var runningRecordClient
    @Dependency(\.weatherClient) var weatherClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Scope(state: \.healthKitWorkout, action: \.healthKitWorkout) {
            HealthKitWorkoutFeature()
        }

        Scope(state: \.condition, action: \.condition) {
            RunningConditionFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                if let record = state.existingRecord {
                    state.weather = record.weather
                    state.selectedDifficultyLevel = record.difficultyLevel
                }
                return .none

            case .healthKitWorkout:
                return .none

            case .condition:
                return .none

            case .updateSelectedDifficultyLevel(let level):
                state.selectedDifficultyLevel = level
                return .none

            case .saveRecord:
                guard let healthKitWorkout = state.healthKitWorkout.data else { return .none }
                state.isLoading = true
                state.errorMassage = nil

                let location = extractLocationFromRoute(healthKitWorkout.routeData)
                let yearMonthDay = YearMonthDay(date: healthKitWorkout.startDate)
                let condition = state.condition
                let existingRecordId = state.existingRecord?.id
                let mode = state.mode
                let difficultyLevel = state.selectedDifficultyLevel

                let startInterval = healthKitWorkout.startDate.timeIntervalSince1970
                let endInterval = healthKitWorkout.endDate.timeIntervalSince1970
                let middleInterval = (startInterval + endInterval) / 2.0
                let middleTime = Date(timeIntervalSince1970: middleInterval)

                return .run { send in
                    do {
                        let weather: WeatherData?
                        if let location = location {
                            do {
                                weather = try await weatherClient.fetchWeather(middleTime, location)
                                await send(.weatherFetched(weather))
                            } catch {
                                AppLogger.addRecord.warning("날씨 조회 실패: \(error.localizedDescription)")
                                weather = nil
                                await send(.weatherFetched(nil))
                            }
                        } else {
                            weather = nil
                        }

                        let record = await RunningRecord(
                            id: existingRecordId ?? UUID(),
                            yearMonthDay: yearMonthDay,
                            distanceInKilometers: healthKitWorkout.distance,
                            durationInSeconds: healthKitWorkout.duration,
                            averagePace: healthKitWorkout.averagePace,
                            averageHeartRate: healthKitWorkout.averageHeartRate,
                            averageCadence: healthKitWorkout.averageCadence,
                            painAreas: Array(condition.selectedPainAreas),
                            runningStyle: condition.selectedRunningStyle,
                            condition: RunningCondition(
                                sleep: Int(condition.sleepHours),
                                meal: condition.hadMeal,
                                alcohol: condition.hadAlcohol,
                                memo: condition.memo.isEmpty ? nil : condition.memo
                            ),
                            shoes: condition.selectedShoe?.id ?? "",
                            weather: weather,
                            difficultyLevel: difficultyLevel,
                            routeData: healthKitWorkout.routeData,
                            activeEnergyBurned: healthKitWorkout.activeEnergyBurned,
                            runningVerticalOscillation: healthKitWorkout.runningVerticalOscillation,
                            runningGroundContactTime: healthKitWorkout.runningGroundContactTime,
                            walkingStepLength: healthKitWorkout.walkingStepLength,
                            hasMap: healthKitWorkout.routeData != nil,
                            startTime: healthKitWorkout.startDate,
                            endTime: healthKitWorkout.endDate
                        )

                        if mode == .add {
                            try await runningRecordClient.saveRecord(record)
                        } else {
                            try await runningRecordClient.updateRecord(record)
                        }

                        await send(.recordSaved)
                    } catch {
                        if let runningRecordError = error as? SwiftDataError {
                            await send(.recordSaveFailed(runningRecordError.errorDescription ?? runningRecordError.localizedDescription))
                        } else {
                            await send(.recordSaveFailed(error.localizedDescription))
                        }
                    }
                }

            case .weatherFetched(let weather):
                state.weather = weather
                return .none

            case .recordSaved:
                state.isLoading = false
                return .run { _ in
                    await dismiss()
                }

            case .recordSaveFailed(let errorMassage):
                state.isLoading = false
                state.errorMassage = errorMassage
                return .none
            }
        }
    }

    private func extractLocationFromRoute(_ routeData: Data?) -> CLLocationCoordinate2D? {
        guard let routeData = routeData,
              let coordinates = try? JSONDecoder().decode([Location].self, from: routeData),
              !coordinates.isEmpty else {
            return nil
        }

        let first = coordinates.first!
        let last = coordinates.last!
        let midLatitude = (first.latitude + last.latitude) / 2.0
        let midLongitude = (first.longitude + last.longitude) / 2.0

        return CLLocationCoordinate2D(latitude: midLatitude, longitude: midLongitude)
    }
}
