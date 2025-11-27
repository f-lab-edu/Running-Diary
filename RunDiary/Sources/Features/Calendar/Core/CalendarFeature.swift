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
        fileprivate(set) var healthKitDatas: [YearMonthDay: [HealthKitData]]
        fileprivate(set) var runningRecords: [YearMonthDay: [RunningRecord]]
        fileprivate(set) var dailyRecords: [YearMonthDay: DailyRecord]
        fileprivate(set) var monthlyTotals: [YearMonth: Double] = [:]
        fileprivate(set) var selectedDate: YearMonthDay
        fileprivate(set) var isLoading: Bool = false

        fileprivate(set) var lastVisibleMonth: YearMonth?
        var canAutoScrollToToday: Bool {
            guard let lastVisibleMonth else { return false }
            return lastVisibleMonth < YearMonth(date: .now)
        }

        init(
            selectedDate: YearMonthDay,
            healthKitDatas: [YearMonthDay: [HealthKitData]] = [:],
            runningRecords: [YearMonthDay: [RunningRecord]] = [:],
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
            self.healthKitDatas = healthKitDatas
            self.runningRecords = runningRecords
            self.dailyRecords = dailyRecords
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case fetchRecords(startDate: YearMonthDay, endDate: YearMonthDay)
        case healthKitDataFetched([YearMonthDay: [HealthKitData]])
        case runningRecordsFetched([YearMonthDay: [RunningRecord]])
        case mergeDailyRecords(healthKitDatas: [YearMonthDay: [HealthKitData]], runningRecords: [YearMonthDay: [RunningRecord]])
        case recordsFetchedFailure(CalendarError)
        case oldestMonthBecameVisible
        case fetchOlderRecords
        case saveLastVisibleMonth(YearMonth)
        case selectDate(YearMonthDay)
        case navigateToDiary
        case delegate(Delegate)

        enum Delegate {
            case dailyRecordSaved([YearMonthDay: DailyRecord])
        }
    }

    // MARK: - Dependency

    @Dependency(\.runningRecordClient) var runningRecordClient
    @Dependency(\.healthKitClient) var healthKitClient

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
                        try await healthKitClient.ensureAuthorizationIfNeeded()
                        async let healthKitDatas = try await healthKitClient.fetchRunningDataBetweenDates(startDate.toDate(), endDate.toDate())
                        async let runningRecords = try await runningRecordClient.fetchRecords(startDate.toDate(), endDate.toDate())
                        let groupedHealthKitDatas = try await Dictionary(grouping: healthKitDatas, by: { $0.yearMonthDay })
                        let groupedRunningRecords = try await Dictionary(grouping: runningRecords, by: { $0.yearMonthDay })

                        await send(.healthKitDataFetched(groupedHealthKitDatas))
                        await send(.runningRecordsFetched(groupedRunningRecords))
                        await send(.mergeDailyRecords(healthKitDatas: groupedHealthKitDatas, runningRecords: groupedRunningRecords))
                    } catch {
                        let errorMessage = error.localizedDescription
                        await send(.recordsFetchedFailure(.fetchFailed(underlyingError: errorMessage)))
                    }
                }

            case let .healthKitDataFetched(healthKitDatas):
                state.healthKitDatas.merge(healthKitDatas) { _, new in new }
                AppLogger.calendar.info("healthKitDataFetched 완료 - 총 저장된 날짜 수: \(state.healthKitDatas.count)")
                return .none

            case let .runningRecordsFetched(runninRecords):
                state.runningRecords.merge(runninRecords) { _, new in new }
                AppLogger.calendar.info("repositoryRecordsFetched 완료 - 총 저장된 날짜 수: \(state.runningRecords.count)")

                for (yearMonthDay, records) in runninRecords {
                    let yearMonth = yearMonthDay.toYearMonth()
                    let totalDistances = records.reduce(0.0) { $0 + $1.distanceInKilometers }
                    state.monthlyTotals.updateValue(totalDistances, forKey: yearMonth)
                }

                return .none

            case let .mergeDailyRecords(healthKitDatas, runningRecords):
                AppLogger.calendar.debug("mergeDailyRecords 시작")

                var currentDate = state.startDate

                while currentDate <= state.endDate {
                    if state.dailyRecords[currentDate] == nil {
                        let healthKitDatasOnDate = healthKitDatas[currentDate] ?? []
                        let runningRecordsOnDate = runningRecords[currentDate] ?? []

                        // HealthKit 데이터 중 저장된 기록과 중복되지 않는 것만 필터링
                        let filteredHealthKitRecords = healthKitDatasOnDate.filter { healthKitData in
                            !runningRecordsOnDate.contains(where: { $0.startTime == healthKitData.startDate })
                        }
                        let sortedHealthKitRecords = filteredHealthKitRecords.sorted { $0.startDate < $1.startDate }

                        let dailyRecord = DailyRecord(
                            yearMonthDay: currentDate,
                            healthKitDatas: sortedHealthKitRecords,
                            savedRecords: runningRecordsOnDate
                        )

                        state.dailyRecords.updateValue(dailyRecord, forKey: currentDate)
                    }

                    guard let nextDate = currentDate.add(day: 1) else {
                        break
                    }
                    currentDate = nextDate
                }

                state.isLoading = false
                AppLogger.calendar.info("mergeDailyRecords 완료 - 총 DailyRecord 수: \(state.dailyRecords.count)")

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

            case .delegate:
                return .none
            }
        }
    }
}
