//
//  DailyDetailFeature.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct DailyDetailFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var selectedDate: Date = Calendar.current.startOfDay(for: Date())
        var dates: [Date] = []
        var runningRecord: RunningRecord?
        var isLoading: Bool = false
        var errorMessage: String?
        @Presents var addRecord: AddRecordFeature.State?
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case dateSelected(Date)
        case fetchRecordForSelectedDate
        case recordFetchedSuccess(RunningRecord?)
        case recordFetchedFailure(String)
        case showAddRecord
        case addRecord(PresentationAction<AddRecordFeature.Action>)
    }

    // MARK: - Dependency

    @Dependency(\.repositoryClient) var repositoryClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 날짜 배열 초기화
                if state.dates.isEmpty {
                    let calendar = Calendar.current
                    let today = Date()
                    var dateArray: [Date] = []
                    for offset in -14...14 {
                        if let date = calendar.date(byAdding: .day, value: offset, to: today) {
                            dateArray.append(calendar.startOfDay(for: date))
                        }
                    }
                    state.dates = dateArray
                }
                return .send(.fetchRecordForSelectedDate)

            case let .dateSelected(date):
                state.selectedDate = date
                return .send(.fetchRecordForSelectedDate)

            case .fetchRecordForSelectedDate:
                state.isLoading = true
                state.errorMessage = nil

                let selectedDate = state.selectedDate
                return .run { send in
                    do {
                        let record = try await repositoryClient.fetch(selectedDate)
                        await send(.recordFetchedSuccess(record))
                    } catch {
                        await send(.recordFetchedFailure(error.localizedDescription))
                    }
                }

            case let .recordFetchedSuccess(record):
                state.isLoading = false
                state.runningRecord = record
                state.errorMessage = nil
                return .none

            case let .recordFetchedFailure(errorMessage):
                state.isLoading = false
                state.runningRecord = nil
                state.errorMessage = "기록을 불러올 수 없습니다: \(errorMessage)"
                return .none

            case .showAddRecord:
                let mode: RecordMode = state.runningRecord == nil ? .add : .edit
                state.addRecord = AddRecordFeature.State(
                    mode: mode,
                    date: state.selectedDate,
                    existingRecord: state.runningRecord
                )
                return .none

            case .addRecord(.presented(.satisfactionSaved)):
                // 만족도 저장 후 닫힘 - 기록 새로고침
                state.addRecord = nil
                return .send(.fetchRecordForSelectedDate)

            case .addRecord(.dismiss):
                // 닫기
                state.addRecord = nil
                return .none

            case .addRecord:
                return .none
            }
        }
        .ifLet(\.$addRecord, action: \.addRecord) {
            AddRecordFeature()
        }
    }
}
