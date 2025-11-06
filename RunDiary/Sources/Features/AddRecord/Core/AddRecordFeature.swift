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
            existingRecord == nil ? .add : .edit
        }

        let date: Date
        var existingRecord: RunningRecord?
        var healthKitData: HealthKitDataFeature.State
        var condition: RunningConditionFeature.State
        var selectedDifficultyLevel: DifficultyLevel?

        var weather: WeatherData?

        var isLoading: Bool = false
        var errorMessage: String?
        @Presents var authorizationAlert: AlertState<AlertAction>?
        @Presents var emptyHealthKitDataAlert: AlertState<EmptyHealthKitDataAlertAction>?

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
        case weatherFetched(WeatherData?)
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
                    )
                } else {
                    // add mode: HealthKit
                    return .send(.healthKitData(.loadData(state.date)))
                }

            case .healthKitData(let healthKitDataAction):
                switch healthKitDataAction {
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

                // 중간 시간 계산
                let middleTime: Date?
                if let startDate = healthKitData.startDate, let endDate = healthKitData.endDate {
                    let startInterval = startDate.timeIntervalSince1970
                    let endInterval = endDate.timeIntervalSince1970
                    let middleInterval = (startInterval + endInterval) / 2.0
                    middleTime = Date(timeIntervalSince1970: middleInterval)
                } else {
                    middleTime = nil
                }

                return .run { send in
                    do {
                        // Fetch weather using middle time and middle location
                        let weather: WeatherData?
                        if let middleTime = middleTime, let location = location {
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

                        // Encode route data before saving
                        let encodedRouteData = try? DataMapper.encode(from: healthKitData.routeData)

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
                            routeData: encodedRouteData,
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

    private func extractLocationFromRoute(_ coordinates: [HealthKitCoordinateData]?) -> CLLocationCoordinate2D? {
        guard let coordinates = coordinates, !coordinates.isEmpty else {
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
