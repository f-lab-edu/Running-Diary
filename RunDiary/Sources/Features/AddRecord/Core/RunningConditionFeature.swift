//
//  RunningConditionFeature.swift
//  RunDiary
//
//  Created by Claude on 10/22/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct RunningConditionFeature {
    @ObservableState
    struct State: Equatable {
        // Pain & Style
        var selectedPainAreas: Set<PainArea> = []
        var selectedRunningStyle: RunninStyle?

        // Condition
        var sleepHours: String = ""
        var hadMeal: Bool = false
        var hadAlcohol: Bool = false
        var memo: String = ""

        // Shoes
        var selectedShoe: String?
        var shoes: [ShoeModel] = []
        var isLoadingShoes: Bool = false
        var errorMessage: String?

        // Static Options
        let painAreaOptions = PainArea.allCases
        let runningStyleOptions = RunninStyle.allCases
    }

    enum Action {
        case loadShoes
        case shoesLoaded([ShoeModel])
        case shoesLoadFailed(String)
        case updateSelectedPainAreas(Set<PainArea>)
        case updateSelectedRunningStyle(RunninStyle?)
        case updateSleepHours(String)
        case updateHadMeal(Bool)
        case updateHadAlcohol(Bool)
        case updateMemo(String)
        case updateSelectedShoe(String?)
        case loadFromRecord(RunningRecord)
    }

    @Dependency(\.shoeClient) var shoeClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadShoes:
                state.isLoadingShoes = true
                return .run { send in
                    do {
                        let shoes = try await shoeClient.fetchShoes()
                        await send(.shoesLoaded(shoes))
                    } catch {
                        await send(.shoesLoadFailed(error.localizedDescription))
                    }
                }

            case let .shoesLoaded(shoes):
                state.isLoadingShoes = false
                state.shoes = shoes
                state.errorMessage = nil
                return .none

            case let .shoesLoadFailed(error):
                state.isLoadingShoes = false
                state.errorMessage = "신발 목록을 불러올 수 없습니다: \(error)"
                return .none

            case let .updateSelectedPainAreas(areas):
                state.selectedPainAreas = areas
                return .none

            case let .updateSelectedRunningStyle(style):
                state.selectedRunningStyle = style
                return .none

            case let .updateSleepHours(hours):
                state.sleepHours = hours
                return .none

            case let .updateHadMeal(value):
                state.hadMeal = value
                return .none

            case let .updateHadAlcohol(value):
                state.hadAlcohol = value
                return .none

            case let .updateMemo(text):
                state.memo = text
                return .none

            case let .updateSelectedShoe(shoe):
                state.selectedShoe = shoe
                return .none

            case let .loadFromRecord(record):
                state.selectedPainAreas = Set(record.painAreas)
                state.selectedRunningStyle = record.runningStyle
                state.sleepHours = record.condition.sleep.map { String($0) } ?? ""
                state.hadMeal = record.condition.meal
                state.hadAlcohol = record.condition.alcohol
                state.memo = record.condition.memo ?? ""
                state.selectedShoe = record.shoes
                return .none
            }
        }
    }
}
