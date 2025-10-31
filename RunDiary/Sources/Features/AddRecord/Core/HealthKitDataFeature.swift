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
        var data: HealthKitDataModel?
        var isDataLoaded: Bool = false
        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case loadData(Date)
        case dataLoaded(HealthKitRunningData)
        case dataLoadFailed(String)
        case healthStoreAuthorizationDenied
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
                            throw HealthKitError.dataNotFound
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
                state.errorMessage = "\(L10n.Healthkit.Error.fetchContext): \(error)"
                state.isDataLoaded = false
                return .none

            case .healthStoreAuthorizationDenied:
                return .none

            case let .loadFromRecord(record):
                state.data = HealthKitDataModel(
                    distance: record.distanceInKilometers,
                    durationInSeconds: record.durationInSeconds,
                    averagePace: record.averagePace,
                    averageHeartRate: record.averageHeartRate,
                    averageCadence: record.averageCadence,
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
