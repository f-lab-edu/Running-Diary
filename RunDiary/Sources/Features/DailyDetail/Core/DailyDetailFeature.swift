//
//  DailyDetailFeature.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import ComposableArchitecture
import Foundation
import Models

@Reducer
struct DailyDetailFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var selectedDate: Date = Calendar.current.startOfDay(for: Date())
        var currentWeekDates: [Date] = []
        var cachedRecords: [Date: RunningRecord] = [:]
        var isLoading: Bool = false
        var errorMessage: String?
        @Presents var addRecord: AddRecordFeature.State?

        /// 선택된 날짜의 기록을 캐시에서 조회
        var currentRecord: RunningRecord? {
            let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
            return cachedRecords[normalizedDate]
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case dateSelected(Date)
        case weekChanged(offset: Int)
        case fetchWeekRecords
        case weekRecordsFetchedSuccess([RunningRecord])
        case weekRecordsFetchedFailure(String)
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
                AppLogger.dailyDetail.debug("onAppear - 화면 표시됨")
                // 현재 주의 날짜들로 초기화
                if state.currentWeekDates.isEmpty {
                    let today = Date()
                    state.currentWeekDates = DateHelper.getWeekDates(for: today)
                    AppLogger.dailyDetail.info("주간 날짜 초기화 완료 - 시작일: \(state.currentWeekDates.first?.description ?? "nil")")
                }
                return .send(.fetchWeekRecords)

            case let .dateSelected(date):
                state.selectedDate = date
                AppLogger.dailyDetail.debug("dateSelected - 선택된 날짜: \(date)")

                // 캐시 히트 확인
                let calendar = Calendar.current
                let normalizedDate = calendar.startOfDay(for: date)
                if state.cachedRecords[normalizedDate] != nil {
                    // 캐시 히트: fetch 생략
                    AppLogger.dailyDetail.info("캐시 히트 - 날짜: \(normalizedDate), fetch 생략")
                    return .none
                } else {
                    // 캐시 미스: 주 단위 fetch
                    AppLogger.dailyDetail.notice("캐시 미스 - 날짜: \(normalizedDate), 주 단위 fetch 시작")
                    return .send(.fetchWeekRecords)
                }

            case let .weekChanged(offset):
                AppLogger.dailyDetail.debug("weekChanged - offset: \(offset)")
                // 현재 주에서 N주 이동
                let calendar = Calendar.current
                let currentWeekStart = state.currentWeekDates.first ?? state.selectedDate
                let newWeekStart = DateHelper.addWeeks(offset, to: currentWeekStart)
                state.currentWeekDates = DateHelper.getWeekDates(for: newWeekStart)
                AppLogger.dailyDetail.info("주 변경 완료 - 새 시작일: \(newWeekStart)")

                // 선택된 날짜를 새 주의 같은 요일로 이동
                if let selectedDateWeekday = calendar.dateComponents([.weekday], from: state.selectedDate).weekday,
                   let newSelectedDate = state.currentWeekDates.first(where: {
                       calendar.dateComponents([.weekday], from: $0).weekday == selectedDateWeekday
                   }) {
                    state.selectedDate = newSelectedDate
                } else {
                    // 같은 요일이 없으면 새 주의 첫날(월요일)로 이동
                    state.selectedDate = newWeekStart
                }

                // 새 주의 선택된 날짜가 캐시에 있는지 확인
                let normalizedDate = calendar.startOfDay(for: state.selectedDate)
                if state.cachedRecords[normalizedDate] != nil {
                    // 캐시 히트: fetch 생략
                    AppLogger.dailyDetail.info("캐시 히트 - 날짜: \(normalizedDate), fetch 생략")
                    return .none
                } else {
                    // 캐시 미스: 주 단위 fetch
                    AppLogger.dailyDetail.notice("캐시 미스 - 날짜: \(normalizedDate), 주 단위 fetch 시작")
                    return .send(.fetchWeekRecords)
                }

            case .fetchWeekRecords:
                guard let weekStart = state.currentWeekDates.first,
                      let weekEnd = state.currentWeekDates.last else {
                    AppLogger.dailyDetail.warning("fetchWeekRecords 실패 - currentWeekDates가 비어있음")
                    return .none
                }

                state.isLoading = true
                state.errorMessage = nil
                AppLogger.dailyDetail.debug("fetchWeekRecords 시작 - weekStart: \(weekStart), weekEnd: \(weekEnd)")

                return .run { send in
                    let startTime = Date()
                    do {
                        // 주 단위 범위 조회
                        let records = try await repositoryClient.fetchRecords(weekStart, weekEnd)
                        let elapsed = Date().timeIntervalSince(startTime)
                        AppLogger.dailyDetail.info("fetchWeekRecords 성공 - count: \(records.count), elapsed: \(String(format: "%.3f", elapsed))s")
                        await send(.weekRecordsFetchedSuccess(records))
                    } catch {
                        let elapsed = Date().timeIntervalSince(startTime)
                        AppLogger.dailyDetail.error("fetchWeekRecords 실패 - error: \(error.localizedDescription), elapsed: \(String(format: "%.3f", elapsed))s")
                        await send(.weekRecordsFetchedFailure(error.localizedDescription))
                    }
                }

            case let .weekRecordsFetchedSuccess(records):
                state.isLoading = false
                state.errorMessage = nil

                // 캐시 업데이트: 배열을 Dictionary로 변환
                let calendar = Calendar.current
                for record in records {
                    let normalizedDate = calendar.startOfDay(for: record.date)
                    state.cachedRecords[normalizedDate] = record
                }

                AppLogger.dailyDetail.info("weekRecordsFetchedSuccess - \(records.count)개 레코드 캐시에 저장 완료, 총 캐시 크기: \(state.cachedRecords.count)")

                return .none

            case let .weekRecordsFetchedFailure(errorMessage):
                state.isLoading = false
                state.errorMessage = "기록을 불러올 수 없습니다: \(errorMessage)"
                AppLogger.dailyDetail.error("weekRecordsFetchedFailure - errorMessage: \(errorMessage)")
                return .none

            case .showAddRecord:
                let mode = state.currentRecord != nil ? "편집" : "추가"
                AppLogger.dailyDetail.debug("showAddRecord - mode: \(mode), date: \(state.selectedDate)")
                state.addRecord = AddRecordFeature.State(
                    date: state.selectedDate,
                    existingRecord: state.currentRecord
                )
                return .none

            case .addRecord(.presented(.recordSaved)):
                // 레코드 저장 후 닫힘 - 캐시 무효화 및 새로고침
                AppLogger.dailyDetail.info("recordSaved - 캐시 무효화 및 새로고침 시작")
                state.addRecord = nil
                state.cachedRecords.removeAll()
                return .send(.fetchWeekRecords)

            case .addRecord(.dismiss):
                // 닫기
                AppLogger.dailyDetail.debug("addRecord dismiss - 기록 추가/편집 화면 닫힘")
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
