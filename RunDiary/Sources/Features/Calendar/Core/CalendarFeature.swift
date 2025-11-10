//
//  CalendarFeature.swift
//  RunDiary
//
//  Created by Claude on 11/3/25.
//

import ComposableArchitecture
import Foundation
import Models

@Reducer
struct CalendarFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable {
        fileprivate(set) var startDate: YearMonthDay
        fileprivate(set) var endDate: YearMonthDay
        fileprivate(set) var recordsByDate: [YearMonthDay: RunningRecord?] = [:]
        fileprivate(set) var monthlyTotals: [YearMonth: Double] = [:]
        fileprivate(set) var selectedDate: YearMonthDay
        fileprivate(set) var isLoading: Bool = false

        fileprivate(set) var lastVisibleMonth: YearMonth?
        var canAutoScrollToToday: Bool {
            guard let lastVisibleMonth else { return false }
            return lastVisibleMonth < YearMonth(date: .now)
        }

        init(selectedDate: YearMonthDay) {
            let today = Date.now
            let calendar = Calendar.current
            self.startDate = selectedDate.add(month: -6) ?? YearMonthDay(date: calendar.date(byAdding: .month, value: -6, to: today)!)
            self.endDate = YearMonthDay(date: today)
            self.selectedDate = selectedDate
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case fetchRecords(startDate: YearMonthDay, endDate: YearMonthDay)
        case recordsFetchedSuccess([RunningRecord])
        case recordsFetchedFailure(CalendarError)
        case oldestMonthBecameVisible
        case fetchOlderRecords
        case saveLastVisibleMonth(YearMonth)
        case selectDate(YearMonthDay)
        case navigateToDiary
    }

    // MARK: - Dependency

    @Dependency(\.repositoryClient) var repositoryClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                AppLogger.calendar.debug("onAppear - 캘린더 화면 표시됨")
                AppLogger.calendar.info("초기 날짜 범위 설정 - startDate: \(state.startDate), endDate: \(state.endDate)")
                return .send(.fetchRecords(startDate: state.startDate, endDate: state.endDate))

            case let .fetchRecords(startDate, endDate):
                guard startDate <= endDate else {
                    AppLogger.calendar.error("fetchRecords 실패 - 잘못된 날짜 범위: startDate: \(startDate), endDate: \(endDate)")
                    return .send(.recordsFetchedFailure(.dateRangeInvalid))
                }

                state.isLoading = true
                AppLogger.calendar.debug("fetchRecords 시작 - startDate: \(startDate), endDate: \(endDate)")

                return .run { send in
                    let fetchStartTime = Date.now
                    do {
                        // 날짜 범위로 기록 조회
                        let records = try await repositoryClient.fetchRecords(startDate.toDate(), endDate.toDate())
                        let elapsed = Date.now.timeIntervalSince(fetchStartTime)
                        AppLogger.calendar.info("fetchRecords 성공 - count: \(records.count), elapsed: \(String(format: "%.3f", elapsed))s")
                        await send(.recordsFetchedSuccess(records))
                    } catch {
                        let elapsed = Date.now.timeIntervalSince(fetchStartTime)
                        let errorMessage = error.localizedDescription
                        AppLogger.calendar.error("fetchRecords 실패 - error: \(errorMessage), elapsed: \(String(format: "%.3f", elapsed))s")
                        await send(.recordsFetchedFailure(.fetchFailed(underlyingError: errorMessage)))
                    }
                }

            case let .recordsFetchedSuccess(records):
                state.isLoading = false

                // 1. records를 날짜별로 매핑 (정규화된 날짜를 키로 사용)
                let recordsByDate = Dictionary(uniqueKeysWithValues: records.map { record in
                    (record.yearMonthDay, record)
                })

                // 2. startDate부터 endDate까지 모든 날짜를 순회하며 딕셔너리에 저장
                var currentDate = state.startDate

                while currentDate <= state.endDate {
                    // 해당 날짜의 기록이 있으면 저장, 없으면 nil 저장
                    if state.recordsByDate[currentDate] == nil {
                        state.recordsByDate[currentDate] = recordsByDate[currentDate]
                    }

                    guard let nextDate = currentDate.add(day: 1) else {
                        break
                    }
                    currentDate = nextDate
                }

                // 3. 월별 총 거리 계산: 기존 월별 총계에 새로운 레코드의 거리를 추가
                for record in records {
                    let yearMonth = record.yearMonthDay.toYearMonth()
                    state.monthlyTotals[yearMonth, default: 0.0] += record.distanceInKilometers
                }

                AppLogger.calendar.info("recordsFetchedSuccess - \(records.count)개 레코드 처리 완료, 총 캐시 크기: \(state.recordsByDate.count), 월별 집계: \(state.monthlyTotals.count)개 월")

                return .none

            case let .recordsFetchedFailure(error):
                state.isLoading = false
                AppLogger.calendar.error("recordsFetchedFailure - error: \(error.localizedDescription)")
                return .none

            case .oldestMonthBecameVisible:
                AppLogger.calendar.debug("oldestMonthBecameVisible - 가장 오래된 달이 화면에 표시됨")
                return .send(.fetchOlderRecords)

            case .fetchOlderRecords:
                // 현재 startDate에서 6개월 이전으로 확장
                guard let newStartDate = state.startDate.add(month: -6) else {
                    AppLogger.calendar.warning("fetchOlderRecords 실패 - 날짜 계산 오류")
                    return .none
                }

                let oldStartDate = state.startDate
                state.startDate = newStartDate
                AppLogger.calendar.info("fetchOlderRecords - startDate 확장: \(oldStartDate) -> \(newStartDate)")

                // 확장된 범위의 데이터 조회 (newStartDate ~ oldStartDate - 1일)
                guard let fetchEndDate = oldStartDate.add(day: -1) else {
                    AppLogger.calendar.warning("fetchOlderRecords 실패 - fetchEndDate 계산 오류")
                    return .none
                }

                return .send(.fetchRecords(startDate: newStartDate, endDate: fetchEndDate))

            case let .saveLastVisibleMonth(lastVisibleMonth):
    
                state.lastVisibleMonth = lastVisibleMonth
                return .none

            case let .selectDate(selectedDate):
                state.selectedDate = selectedDate
                AppLogger.calendar.info("selectDay - \(state.selectedDate) 선택")
                return .none

            case .navigateToDiary:
                AppLogger.calendar.info("navigateToDiary - \(state.selectedDate) 날짜로 다이어리 이동")
                return .none
            }
        }
    }
}
