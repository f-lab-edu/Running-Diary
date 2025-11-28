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
