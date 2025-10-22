//
//  HealthKitDataFeature.swift
//  RunDiary
//
//  Created by Claude on 10/22/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct HealthKitDataFeature {
    @ObservableState
    struct State: Equatable {
        var distance: Double = 0
        var duration: String = ""
        var averagePace: String = ""
        var averageHeartRate: Int = 0
        var averageCadence: Int = 0
        var routeData: Data?
        var isDataLoaded: Bool = false
        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case loadData(Date)
        case dataLoaded(HealthKitRunningData)
        case dataLoadFailed(String)
        case updateDistance(String)
        case updateDuration(String)
        case updateAveragePace(String)
        case updateAverageHeartRate(String)
        case updateAverageCadence(String)
        case loadFromRecord(RunningRecord)
    }

    @Dependency(\.healthKitClient) var healthKitClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .loadData(date):
                state.isLoading = true
                state.errorMessage = nil

                return .run { send in
                    do {
                        try await healthKitClient.requestAuthorization()
                        if let data = try await healthKitClient.fetchRunningData(date) {
                            await send(.dataLoaded(data))
                        } else {
                            await send(.dataLoadFailed("데이터를 찾을 수 없습니다"))
                        }
                    } catch {
                        await send(.dataLoadFailed(error.localizedDescription))
                    }
                }

            case let .dataLoaded(data):
                state.isLoading = false
                state.distance = data.distance ?? 0
                state.duration = data.duration.map { formatDuration($0) } ?? ""
                state.averagePace = data.averagePace ?? ""
                state.averageHeartRate = data.averageHeartRate ?? 0
                state.averageCadence = data.averageCadence ?? 0
                state.routeData = data.routeData
                state.isDataLoaded = true
                return .none

            case let .dataLoadFailed(error):
                state.isLoading = false
                state.errorMessage = "HealthKit 데이터를 가져올 수 없습니다: \(error)"
                state.isDataLoaded = false
                return .none

            case let .updateDistance(value):
                state.distance = value.toDouble
                return .none

            case let .updateDuration(value):
                state.duration = value
                return .none

            case let .updateAveragePace(value):
                state.averagePace = value
                return .none

            case let .updateAverageHeartRate(value):
                state.averageHeartRate = value.toInt
                return .none

            case let .updateAverageCadence(value):
                state.averageCadence = value.toInt
                return .none

            case let .loadFromRecord(record):
                state.distance = record.distanceInKilometers ?? 0
                state.duration = record.formattedDuration ?? ""
                state.averagePace = record.averagePace ?? ""
                state.averageHeartRate = record.averageHeartRate ?? 0
                state.averageCadence = record.averageCadence ?? 0
                state.routeData = record.routeData
                state.isDataLoaded = true
                return .none
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
