//
//  RunningConditionFeature.swift
//  RunDiary
//
//  Created by Claude on 10/22/25.
//

import ComposableArchitecture
import Foundation

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

      case .shoesLoaded(let shoes):
        state.isLoadingShoes = false
        state.shoes = shoes
        state.errorMessage = nil
        return .none

      case .shoesLoadFailed(let error):
        state.isLoadingShoes = false
        state.errorMessage = "\(L10n.Shoe.Error.fetchContext): \(error)"
        return .none

      case .updateSelectedPainAreas(let areas):
        state.selectedPainAreas = areas
        return .none

      case .updateSelectedRunningStyle(let style):
        state.selectedRunningStyle = style
        return .none

      case .updateSleepHours(let hours):
        state.sleepHours = hours
        return .none

      case .updateHadMeal(let value):
        state.hadMeal = value
        return .none

      case .updateHadAlcohol(let value):
        state.hadAlcohol = value
        return .none

      case .updateMemo(let text):
        state.memo = text
        return .none

      case .updateSelectedShoe(let shoe):
        state.selectedShoe = shoe
        return .none

      case .loadFromRecord(let record):
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
