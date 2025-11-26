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
        let data: HealthKitData?

        init(data: HealthKitData?) {
            if let data {
                self.data = HealthKitData(
                    distance: data.distance,
                    duration: data.duration,
                    averagePace: data.averagePace,
                    averageHeartRate: data.averageHeartRate,
                    averageCadence: data.averageCadence,
                    routeData: data.routeData,
                    startDate: data.startDate,
                    endDate: data.endDate
                )
            } else {
                self.data = nil
            }
        }
    }

    enum Action {
        case loadFromRecord(RunningRecord)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadFromRecord:
                return .none
            }
        }
    }
}
