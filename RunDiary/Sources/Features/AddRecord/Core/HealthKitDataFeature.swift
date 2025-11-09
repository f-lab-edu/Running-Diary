//
//  HealthKitDataFeature.swift
//  RunDiary
//
//  Created by Claude on 10/22/25.
//

import CommonFoundation
import ComposableArchitecture
import Foundation
import Models

@Reducer
struct HealthKitDataFeature {
    @ObservableState
    struct State: Equatable {
        var data: HealthKitDataModel?
        var isDataLoaded: Bool = false

        /// HealthKitRunningData로부터 State를 초기화
        init(healthKitData: HealthKitRunningData) {
            self.data = HealthKitDataModel(
                distance: healthKitData.distance ?? 0,
                durationInSeconds: healthKitData.duration ?? 0,
                averagePace: healthKitData.averagePace ?? "",
                averageHeartRate: healthKitData.averageHeartRate ?? 0,
                averageCadence: healthKitData.averageCadence ?? 0,
                routeData: healthKitData.routeData,
                startDate: healthKitData.startDate,
                endDate: healthKitData.endDate
            )
            self.isDataLoaded = true
        }

        /// 빈 State를 생성하는 기본 초기화
        init() {
            self.data = nil
            self.isDataLoaded = false
        }
    }

    enum Action {
        case loadFromRecord(RunningRecord)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadFromRecord(let record):
                // Decode routeData from Data to [HealthKitCoordinateData]
                let decodedRouteData = decodeRouteData(record.routeData)

                state.data = HealthKitDataModel(
                    distance: record.distanceInKilometers,
                    durationInSeconds: record.durationInSeconds,
                    averagePace: record.averagePace,
                    averageHeartRate: record.averageHeartRate,
                    averageCadence: record.averageCadence,
                    routeData: decodedRouteData,
                    startDate: record.startTime,
                    endDate: record.endTime
                )
                state.isDataLoaded = true
                return .none
            }
        }
    }

    private func decodeRouteData(_ data: Data?) -> [HealthKitCoordinateData]? {
        guard let data = data else {
            return nil
        }

        do {
            return try JSONDecoder().decode([HealthKitCoordinateData].self, from: data)
        } catch {
            AppLogger.addRecord.warning("Failed to decode route data: \(error)")
            return nil
        }
    }
}
