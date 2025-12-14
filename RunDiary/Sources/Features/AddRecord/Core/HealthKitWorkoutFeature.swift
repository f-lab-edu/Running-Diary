//
//  HealthKitWorkoutFeature.swift
//  RunDiary
//
//  Created by Claude on 10/22/25.
//

import CommonFoundation
import ComposableArchitecture
import Foundation
import Models

@Reducer
struct HealthKitWorkoutFeature {
    @ObservableState
    struct State: Equatable {
        let data: HealthKitWorkout?

        init(data: HealthKitWorkout?) {
            self.data = data
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
