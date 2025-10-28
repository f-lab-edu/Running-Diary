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
        let date: Date
        var existingRecord: RunningRecord?

        var mode: RecordMode {
            existingRecord == nil ? .add : .edit
        }

        // MARK: - Child Features
        var healthKitData: HealthKitDataFeature.State
        var condition: RunningConditionFeature.State

        // MARK: - Additional Data
        var weather: Weather?

        // MARK: - UI State
        var isLoading: Bool = false
        var errorMessage: String?
        @Presents var authorizationAlert: AlertState<AlertAction>?
        @Presents var satisfactionDialog: ConfirmationDialogState<SatisfactionAction>?
        var selectedSatisfaction: Int?

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
        case saveRecord
        case weatherFetched(Weather?)
        case recordSaved(RunningRecord)
        case recordSaveFailed(String)
        case setSatisfaction(Int)
        case saveSatisfaction
        case satisfactionSaved(RunningRecord)
        case satisfactionSaveFailed(String)
        case authorizationAlert(PresentationAction<AlertAction>)
        case satisfactionDialog(PresentationAction<SatisfactionAction>)
    }

    enum AlertAction: Equatable {
        case openSettings
        case goBack
    }

    enum SatisfactionAction: Equatable {
        case rate(Int)
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

                let location = extractLocationFromRoute(state.healthKitData.data.routeData)
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
                        let record = await RunningRecord(
                            id: existingRecordId ?? UUID(),
                            date: date,
                            distanceInKilometers: healthKitData.data.distance,
                            durationInSeconds: healthKitData.data.durationInSeconds,
                            averagePace: healthKitData.data.averagePace.isEmpty ? nil : healthKitData.data.averagePace,
                            averageHeartRate: healthKitData.data.averageHeartRate,
                            averageCadence: healthKitData.data.averageCadence,
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
                            routeData: healthKitData.data.routeData,
                            hasMap: healthKitData.data.routeData != nil
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
                state.satisfactionDialog = ConfirmationDialogState {
                    TextState("러닝 만족도")
                } actions: {
                    ButtonState(action: .rate(1)) {
                        TextState("1점")
                    }
                    ButtonState(action: .rate(2)) {
                        TextState("2점")
                    }
                    ButtonState(action: .rate(3)) {
                        TextState("3점")
                    }
                    ButtonState(action: .rate(4)) {
                        TextState("4점")
                    }
                    ButtonState(action: .rate(5)) {
                        TextState("5점")
                    }
                    ButtonState(role: .cancel) {
                        TextState("건너뛰기")
                    }
                } message: {
                    TextState("오늘 러닝에 만족하셨나요?")
                }
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
                        let record = await RunningRecord(
                            id: existingRecordId ?? UUID(),
                            date: date,
                            distanceInKilometers: healthKitData.data.distance,
                            durationInSeconds: healthKitData.data.durationInSeconds,
                            averagePace: healthKitData.data.averagePace.isEmpty ? nil : healthKitData.data.averagePace,
                            averageHeartRate: healthKitData.data.averageHeartRate,
                            averageCadence: healthKitData.data.averageCadence,
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
                            routeData: healthKitData.data.routeData,
                            hasMap: healthKitData.data.routeData != nil
                        )

                        try await repositoryClient.update(record)
                        await send(.satisfactionSaved(record))
                    } catch {
                        await send(.satisfactionSaveFailed(error.localizedDescription))
                    }
                }

            case let .satisfactionSaved(record):
                state.isLoading = false
                state.existingRecord = record
                return .none

            case let .satisfactionSaveFailed(error):
                state.isLoading = false
                state.errorMessage = "만족도 저장에 실패했습니다: \(error)"
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

            case let .satisfactionDialog(.presented(.rate(rating))):
                state.selectedSatisfaction = rating
                return .send(.saveSatisfaction)

            case .satisfactionDialog:
                return .none
            }
        }
        .ifLet(\.$authorizationAlert, action: \.authorizationAlert)
        .ifLet(\.$satisfactionDialog, action: \.satisfactionDialog)
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
