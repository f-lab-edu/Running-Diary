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
        var mode: RecordMode {
            existingRecord == nil ? .add : .edit
        }

        let date: Date
        var existingRecord: RunningRecord?
        var healthKitData: HealthKitDataFeature.State
        var condition: RunningConditionFeature.State
        var selectedDifficultyLevel: DifficultyLevel?

        var weather: Weather?

        var isLoading: Bool = false
        var errorMessage: String?
        @Presents var authorizationAlert: AlertState<AlertAction>?
        @Presents var emptyHealthKitDataAlert: AlertState<EmptyHealthKitDataAlertAction>?

        init(date: Date, existingRecord: RunningRecord? = nil) {
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
        case updateSelectedDifficultyLevel(DifficultyLevel?)
        case saveRecord
        case weatherFetched(Weather?)
        case recordSaved(RunningRecord)
        case recordSaveFailed(String)
        case authorizationAlert(PresentationAction<AlertAction>)
        case emptyHealthKitDataAlert(PresentationAction<EmptyHealthKitDataAlertAction>)
    }

    enum AlertAction: Equatable {
        case openSettings
        case goBack
    }

    enum EmptyHealthKitDataAlertAction: Equatable {
        case goBack
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
                if state.mode == .edit, let record = state.existingRecord {
                    // edit mode: load existing record into child features
                    state.weather = record.weather
                    state.selectedDifficultyLevel = record.difficultyLevel
                    return .merge(
                        .send(.healthKitData(.loadFromRecord(record))),
                        .send(.condition(.loadFromRecord(record))),
                        .send(.condition(.loadShoes))
                    )
                } else {
                    // add mode: HealthKit + shoes 로드
                    return .merge(
                        .send(.healthKitData(.loadData(state.date))),
                        .send(.condition(.loadShoes))
                    )
                }

            case .healthKitData(let healthKitDataAction):
                switch healthKitDataAction{
                case .healthStoreAuthorizationDenied:
                    state.authorizationAlert = AlertState {
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
                case .dataLoadFailed(let message):
                    state.emptyHealthKitDataAlert = AlertState {
                        TextState("피트니스 데이터 가져오기 실패")
                    } actions: {
                        ButtonState(action: .goBack) {
                            TextState("뒤로 가기")
                        }
                    } message: {
                        TextState(message)
                    }
                default:
                    break
                }
                return .none

            case .condition:
                // Handled by RunningConditionFeature
                return .none

            case .updateSelectedDifficultyLevel(let level):
                state.selectedDifficultyLevel = level
                return .none

            case .saveRecord:
                guard let healthKitData = state.healthKitData.data else { return .none }
                state.isLoading = true
                state.errorMessage = nil

                let location = extractLocationFromRoute(healthKitData.routeData)
                let date = state.date
                let condition = state.condition
                let existingRecordId = state.existingRecord?.id
                let mode = state.mode
                let difficultyLevel = state.selectedDifficultyLevel

                return .run { send in
                    do {
                        // Fetch weather
                        let weather = try? await weatherClient.fetchWeather(date, location)
                        await send(.weatherFetched(weather))

                        // Create record
                        let record = await RunningRecord(
                            id: existingRecordId ?? UUID(),
                            date: date,
                            distanceInKilometers: healthKitData.distance,
                            durationInSeconds: healthKitData.durationInSeconds,
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
                            shoes: condition.selectedShoe,
                            weather: weather,
                            difficultyLevel: difficultyLevel,
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
                return .run { _ in
                    await dismiss()
                }

            case let .recordSaveFailed(error):
                state.isLoading = false
                state.errorMessage = "기록 저장에 실패했습니다: \(error)"
                return .none

            case .authorizationAlert(.presented(.openSettings)):
                URLOpener.openSettings()
                return .none

            case .authorizationAlert(.presented(.goBack)):
                return .run { _ in
                    await dismiss()
                }

            case .authorizationAlert:
                return .none

            case .emptyHealthKitDataAlert(.presented(.goBack)):
                return .run { _ in
                    await dismiss()
                }

            case .emptyHealthKitDataAlert:
                return .none
            }
        }
        .ifLet(\.$authorizationAlert, action: \.authorizationAlert)
        .ifLet(\.$emptyHealthKitDataAlert, action: \.emptyHealthKitDataAlert)
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
