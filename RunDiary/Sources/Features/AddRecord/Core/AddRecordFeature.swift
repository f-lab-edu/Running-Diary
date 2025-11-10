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

enum RecordMode: Equatable {
    case add
    case edit
}

@Reducer
struct AddRecordFeature {
    @ObservableState
    struct State: Equatable {
        var mode: RecordMode {
            guard existingRecord == nil else { return .edit }
            return healthKitData.data != nil ? .add : .edit
        }

        var existingRecord: RunningRecord?
        var healthKitData: HealthKitDataFeature.State
        var condition: RunningConditionFeature.State
        var selectedDifficultyLevel: DifficultyLevel?

        var weather: WeatherData?

        var isLoading: Bool = false
        var errorMessage: String?

        /// 메모를 제외한 모든 필수 데이터가 입력되었는지 확인
        var isFormValid: Bool {
            guard healthKitData.data != nil else { return false }
            guard condition.selectedShoe != nil else { return false }
            guard condition.selectedRunningStyle != nil else { return false }
            guard !condition.sleepHours.isEmpty,
                  let sleepHoursValue = Int(condition.sleepHours),
                  sleepHoursValue >= 1 && sleepHoursValue <= 24
            else { return false }
            guard selectedDifficultyLevel != nil else { return false }
            return true
        }

        init(existingRecord: RunningRecord? = nil, healthKitData: HealthKitRecord? = nil) {
            self.existingRecord = existingRecord
            self.healthKitData = HealthKitDataFeature.State(data: healthKitData)
            self.condition = RunningConditionFeature.State(existingRecord: existingRecord)
        }
    }

    enum Action {
        case onAppear
        case healthKitData(HealthKitDataFeature.Action)
        case condition(RunningConditionFeature.Action)
        case updateSelectedDifficultyLevel(DifficultyLevel?)
        case saveRecord
        case weatherFetched(WeatherData?)
        case recordSaved(RunningRecord)
        case recordSaveFailed(String)
    }

    @Dependency(\.repositoryClient) var repositoryClient
    @Dependency(\.weatherClient) var weatherClient
    @Dependency(\.dismiss) var dismiss

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
                if let record = state.existingRecord {
                    state.weather = record.weather
                    state.selectedDifficultyLevel = record.difficultyLevel
                }
                return .none

            case .healthKitData:
                return .none

            case .condition:
                return .none

            case .updateSelectedDifficultyLevel(let level):
                state.selectedDifficultyLevel = level
                return .none

            case .saveRecord:
                guard let healthKitData = state.healthKitData.data else { return .none }
                state.isLoading = true
                state.errorMessage = nil

                let location = extractLocationFromRoute(healthKitData.routeData)
                let yearMonthDay = YearMonthDay(date: healthKitData.startDate)
                let condition = state.condition
                let existingRecordId = state.existingRecord?.id
                let mode = state.mode
                let difficultyLevel = state.selectedDifficultyLevel

                // 중간 시간 계산
                let startInterval = healthKitData.startDate.timeIntervalSince1970
                let endInterval = healthKitData.endDate.timeIntervalSince1970
                let middleInterval = (startInterval + endInterval) / 2.0
                let middleTime = Date(timeIntervalSince1970: middleInterval)

                return .run { send in
                    do {
                        // Fetch weather using middle time and middle location
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

                        // Create record
                        let record = await RunningRecord(
                            id: existingRecordId ?? UUID(),
                            yearMonthDay: yearMonthDay,
                            distanceInKilometers: healthKitData.distance,
                            durationInSeconds: healthKitData.duration,
                            averagePace: healthKitData.averagePace,
                            averageHeartRate: healthKitData.averageHeartRate,
                            averageCadence: healthKitData.averageCadence,
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
                            routeData: healthKitData.routeData,
                            hasMap: healthKitData.routeData != nil,
                            startTime: healthKitData.startDate,
                            endTime: healthKitData.endDate
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

            case .weatherFetched(let weather):
                state.weather = weather
                return .none

            case .recordSaved:
                state.isLoading = false
                return .run { _ in
                    await dismiss()
                }

            case .recordSaveFailed(let error):
                state.isLoading = false
                state.errorMessage = "\(L10n.Record.Error.saveContext): \(error)"
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

        // 시작점과 끝점의 중간 지점 계산
        let first = coordinates.first!
        let last = coordinates.last!
        let midLatitude = (first.latitude + last.latitude) / 2.0
        let midLongitude = (first.longitude + last.longitude) / 2.0

        return CLLocationCoordinate2D(latitude: midLatitude, longitude: midLongitude)
    }
}
