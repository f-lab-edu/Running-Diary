//
//  HealthKitDataFeature.swift
//  RunDiary
//
//  Created by Claude on 10/22/25.
//

import Foundation

import ComposableArchitecture

import CommonFoundation

@Reducer
struct HealthKitDataFeature {
    @ObservableState
    struct State: Equatable {
        var data: HealthKitDataModel = HealthKitDataModel(
            distance: 0,
            durationInSeconds: 0,
            averagePace: "",
            averageHeartRate: 0,
            averageCadence: 0,
            routeData: nil
        )
        var isDataLoaded: Bool = false
        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case loadData(Date)
        case dataLoaded(HealthKitRunningData)
        case dataLoadFailed(String)
        case healthStoreAuthorizationDenied
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
                        try await healthKitClient.ensureAuthorizationIfNeeded()
                        if let data = try await healthKitClient.fetchRunningData(date) {
                            await send(.dataLoaded(data))
                        } else {
                            await send(.dataLoadFailed("데이터를 찾을 수 없습니다"))
                        }
                    } catch {
                        await send(.dataLoadFailed(error.localizedDescription))
                    }
                }

            case let .dataLoaded(healthKitData):
                state.isLoading = false
                state.data = HealthKitDataModel(
                    distance: healthKitData.distance ?? 0,
                    durationInSeconds: healthKitData.duration ?? 0,
                    averagePace: healthKitData.averagePace ?? "",
                    averageHeartRate: healthKitData.averageHeartRate ?? 0,
                    averageCadence: healthKitData.averageCadence ?? 0,
                    routeData: healthKitData.routeData
                )
                state.isDataLoaded = true
                return .none

            case let .dataLoadFailed(error):
                state.isLoading = false
                state.errorMessage = "HealthKit 데이터를 가져올 수 없습니다: \(error)"
                state.isDataLoaded = false
                return .none

            case .healthStoreAuthorizationDenied:
                return .none

            case let .updateDistance(value):
                state.data = HealthKitDataModel(
                    distance: value.toDouble,
                    durationInSeconds: state.data.durationInSeconds,
                    averagePace: state.data.averagePace,
                    averageHeartRate: state.data.averageHeartRate,
                    averageCadence: state.data.averageCadence,
                    routeData: state.data.routeData
                )
                return .none

            case let .updateDuration(value):
                state.data = HealthKitDataModel(
                    distance: state.data.distance,
                    durationInSeconds: parseDuration(value) ?? 0,
                    averagePace: state.data.averagePace,
                    averageHeartRate: state.data.averageHeartRate,
                    averageCadence: state.data.averageCadence,
                    routeData: state.data.routeData
                )
                return .none

            case let .updateAveragePace(value):
                state.data = HealthKitDataModel(
                    distance: state.data.distance,
                    durationInSeconds: state.data.durationInSeconds,
                    averagePace: value,
                    averageHeartRate: state.data.averageHeartRate,
                    averageCadence: state.data.averageCadence,
                    routeData: state.data.routeData
                )
                return .none

            case let .updateAverageHeartRate(value):
                state.data = HealthKitDataModel(
                    distance: state.data.distance,
                    durationInSeconds: state.data.durationInSeconds,
                    averagePace: state.data.averagePace,
                    averageHeartRate: value.toInt,
                    averageCadence: state.data.averageCadence,
                    routeData: state.data.routeData
                )
                return .none

            case let .updateAverageCadence(value):
                state.data = HealthKitDataModel(
                    distance: state.data.distance,
                    durationInSeconds: state.data.durationInSeconds,
                    averagePace: state.data.averagePace,
                    averageHeartRate: state.data.averageHeartRate,
                    averageCadence: value.toInt,
                    routeData: state.data.routeData
                )
                return .none

            case let .loadFromRecord(record):
                state.data = HealthKitDataModel(
                    distance: record.distanceInKilometers ?? 0,
                    durationInSeconds: record.durationInSeconds ?? 0,
                    averagePace: record.averagePace ?? "",
                    averageHeartRate: record.averageHeartRate ?? 0,
                    averageCadence: record.averageCadence ?? 0,
                    routeData: record.routeData
                )
                state.isDataLoaded = true
                return .none
            }
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
