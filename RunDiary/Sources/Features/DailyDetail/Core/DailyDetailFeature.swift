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
        var currentWeekDates: [Date] = []
        var runningRecord: RunningRecord?
        var isLoading: Bool = false
        var errorMessage: String?
        @Presents var addRecord: AddRecordFeature.State?
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case dateSelected(Date)
        case weekChanged(offset: Int)
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
                // 현재 주의 날짜들로 초기화
                if state.currentWeekDates.isEmpty {
                    let today = Date()
                    state.currentWeekDates = DateHelper.getWeekDates(for: today)
                }
                return .send(.fetchRecordForSelectedDate)

            case let .dateSelected(date):
                state.selectedDate = date
                return .send(.fetchRecordForSelectedDate)

            case let .weekChanged(offset):
                // 현재 주에서 N주 이동
                let currentWeekStart = state.currentWeekDates.first ?? state.selectedDate
                let newWeekStart = DateHelper.addWeeks(offset, to: currentWeekStart)
                state.currentWeekDates = DateHelper.getWeekDates(for: newWeekStart)
                // 선택된 날짜를 새 주의 같은 요일로 이동
                if let selectedDateWeekday = Calendar.current.dateComponents([.weekday], from: state.selectedDate).weekday,
                   let newSelectedDate = state.currentWeekDates.first(where: {
                       Calendar.current.dateComponents([.weekday], from: $0).weekday == selectedDateWeekday
                   }) {
                    state.selectedDate = newSelectedDate
                } else {
                    // 같은 요일이 없으면 새 주의 첫날(월요일)로 이동
                    state.selectedDate = newWeekStart
                }
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
                state.errorMessage = "\(L10n.Record.Error.fetchContext): \(errorMessage)"
                return .none

            case .showAddRecord:
                state.addRecord = AddRecordFeature.State(
                    date: state.selectedDate,
                    existingRecord: state.runningRecord
                )
                return .none

            case .addRecord(.presented(.recordSaved)):
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
