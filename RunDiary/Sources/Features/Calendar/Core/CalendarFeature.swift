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
        var startDate: YearMonthDay
        var endDate: YearMonthDay
        var dailyRecords: [YearMonthDay: DailyRecord]
        var monthlyTotals: [YearMonth: Double] = [:]
        var selectedDate: YearMonthDay
        var isLoading: Bool = false

        fileprivate(set) var lastVisibleMonth: YearMonth?
        var isEnabledTodayButton: Bool {
            guard selectedDate == .today else { return true }
            guard let lastVisibleMonth else { return false }
            return lastVisibleMonth < YearMonth(date: .now)
        }

        init(
            selectedDate: YearMonthDay,
            dailyRecords: [YearMonthDay: DailyRecord] = [:]
        ) {
            let today = Date.now
            let calendar = Calendar.current
            self.startDate = selectedDate.add(month: -6) ?? YearMonthDay(date: calendar.date(byAdding: .month, value: -6, to: today)!)

            // endDate: selectedDate + 6개월 (단, today까지의 차이가 6개월 미만이면 today)
            let tentativeEndDate = selectedDate.add(month: 6) ?? YearMonthDay(date: calendar.date(byAdding: .month, value: 6, to: selectedDate.toDate())!)

            // selectedDate month와 today month 간의 개월 수 차이 계산
            let todayYearMonthDay = YearMonthDay(date: today)
            let selectedMonth = selectedDate.year * 12 + selectedDate.month
            let todayMonth = todayYearMonthDay.year * 12 + todayYearMonthDay.month
            let monthDiff = todayMonth - selectedMonth

            // 차이가 6개월 미만이면 endDate = today, 아니면 tentativeEndDate
            self.endDate = monthDiff < 6 ? todayYearMonthDay : tentativeEndDate

            self.selectedDate = selectedDate
            self.dailyRecords = dailyRecords
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case fetchRecords(startDate: YearMonthDay, endDate: YearMonthDay)
        case recordsFetched([YearMonthDay: DailyRecord])
        case recordsFetchedFailure(CalendarError)
        case oldestMonthBecameVisible
        case fetchOlderRecords
        case saveLastVisibleMonth(YearMonth)
        case selectDate(YearMonthDay)
        case navigateToDiary
        case delegate(Delegate)
        case refreshAll

        enum Delegate {
            case dailyRecordSaved([YearMonthDay: DailyRecord])
        }
    }

    // MARK: - Dependency

    @Dependency(\.runningRecordClient) var runningRecordClient
    @Dependency(\.swiftDataClient) var swiftDataClient

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
                    do {
                        let dailyRecords = try await runningRecordClient.fetchData(
                            from: startDate,
                            to: endDate
                        )
                        await send(.recordsFetched(dailyRecords))
                    } catch {
                        let errorMessage = error.localizedDescription
                        await send(.recordsFetchedFailure(.fetchFailed(underlyingError: errorMessage)))
                    }
                }

            case let .recordsFetched(dailyRecords):
                state.dailyRecords.merge(dailyRecords) { _, new in new }
                state.isLoading = false
                AppLogger.calendar.info("recordsFetched 완료 - 총 DailyRecord 수: \(state.dailyRecords.count)")

                // monthlyTotals 계산
                for (yearMonthDay, dailyRecord) in dailyRecords {
                    let yearMonth = yearMonthDay.toYearMonth()
                    let totalDistances = dailyRecord.savedRecords.reduce(0.0) { $0 + $1.distanceInKilometers }
                    state.monthlyTotals[yearMonth, default: 0] += totalDistances
                }

                return .send(.delegate(.dailyRecordSaved(state.dailyRecords)))

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

            case .refreshAll:
                AppLogger.calendar.info("refreshAll - 전체 새로고침 시작")

                // 1. Feature cache clear
                state.dailyRecords.removeAll()
                state.monthlyTotals.removeAll()

                // 2. SwiftData cache clear (Repository의 캐시 제거)
                swiftDataClient.clearCache()
                AppLogger.calendar.debug("SwiftData cache cleared")

                // 3. 현재 범위 다시 fetch (HealthKit은 자동으로 fresh fetch됨)
                return .send(.fetchRecords(startDate: state.startDate, endDate: state.endDate))

            case .delegate:
                return .none
            }
        }
    }
}
