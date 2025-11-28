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
        var selectedDate: YearMonthDay
        var currentWeekDates: [YearMonthDay]
        var dailyRecords: [YearMonthDay: DailyRecord]
        var healthKitDatas: [YearMonthDay: [HealthKitData]]
        var runningRecords: [YearMonthDay: [RunningRecord]]
        var isLoading: Bool = false
        var error: DailyDetailError? = nil
        @Presents var addRecord: AddRecordFeature.State?
        @Presents var calendar: CalendarFeature.State?

        var currentDailyRecord: DailyRecord? {
            return dailyRecords[selectedDate]
        }

        init(
            selectedDate: YearMonthDay = .today,
            currentWeekDates: [YearMonthDay] = [],
            cachedRecords: [YearMonthDay: DailyRecord] = [:],
            healthKitDatas: [YearMonthDay: [HealthKitData]] = [:],
            runningRecords: [YearMonthDay: [RunningRecord]] = [:],
            isLoading: Bool = false,
            addRecord: AddRecordFeature.State? = nil,
            calendar: CalendarFeature.State? = nil
        ) {
            self.selectedDate = selectedDate
            self.currentWeekDates = currentWeekDates
            self.dailyRecords = cachedRecords
            self.healthKitDatas = healthKitDatas
            self.runningRecords = runningRecords
            self.isLoading = isLoading
            self.addRecord = addRecord
            self.calendar = calendar
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case dateSelected(YearMonthDay)
        case weekChanged(offset: Int)
        case fetchWeekRecords
        case healthKitDatasFetched([YearMonthDay: [HealthKitData]])
        case runningRecordsFetched([YearMonthDay: [RunningRecord]])
        case mergeDailyRecords(healthKitDatas: [YearMonthDay: [HealthKitData]], runningRecords: [YearMonthDay: [RunningRecord]])
        case weekRecordsFetchFailed(DailyDetailError)
        case mergeCachedRecordsForRefresh([YearMonthDay])
        case refreshHealthKitForCachedDates
        case healthKitDataRefreshFailed(DailyDetailError)
        case createRecord(HealthKitData)
        case editRecord(RunningRecord)
        case addRecord(PresentationAction<AddRecordFeature.Action>)
        case calendarButtonTapped
        case calendar(PresentationAction<CalendarFeature.Action>)
    }

    // MARK: - Dependency

    @Dependency(\.runningRecordClient) var runningRecordClient
    @Dependency(\.healthKitClient) var healthKitClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                AppLogger.dailyDetail.debug("onAppear - 화면 표시됨")
                // 현재 주의 날짜들로 초기화
                if state.currentWeekDates.isEmpty {
                    state.currentWeekDates = DateHelper.getWeekDates(for: state.selectedDate.toDate()).map { YearMonthDay(date: $0) }
                    AppLogger.dailyDetail.info("주간 날짜 초기화 완료 - 시작일: \(state.currentWeekDates.first ?? nil)")
                }
                return .send(.fetchWeekRecords)

            case let .dateSelected(date):
                state.selectedDate = date
                AppLogger.dailyDetail.debug("dateSelected - 선택된 날짜: \(date)")

                // 캐시 히트 확인
                if state.dailyRecords[date] != nil {
                    // 캐시 히트: fetch 생략
                    AppLogger.dailyDetail.info("캐시 히트 - 날짜: \(date), fetch 생략")
                    return .none
                } else {
                    // 캐시 미스: 주 단위 fetch
                    AppLogger.dailyDetail.notice("캐시 미스 - 날짜: \(date), 주 단위 fetch 시작")
                    return .send(.fetchWeekRecords)
                }

            case let .weekChanged(offset):
                AppLogger.dailyDetail.debug("weekChanged - offset: \(offset)")
                
                // 현재 주에서 N주 이동
                let calendar = Calendar.current
                let currentWeekStart = state.currentWeekDates.first ?? state.selectedDate
                let newWeekStart = DateHelper.addWeeks(offset, to: currentWeekStart.toDate())
                state.currentWeekDates = DateHelper.getWeekDates(for: newWeekStart).map { YearMonthDay(date: $0) }
                AppLogger.dailyDetail.info("주 변경 완료 - 새 시작일: \(newWeekStart)")

                // 선택된 날짜를 새 주의 같은 요일로 이동
                if let selectedDateWeekday = calendar.dateComponents([.weekday], from: state.selectedDate.toDate()).weekday,
                   let newSelectedDate = state.currentWeekDates.first(where: {
                       calendar.dateComponents([.weekday], from: $0.toDate()).weekday == selectedDateWeekday
                   }) {
                    state.selectedDate = newSelectedDate
                } else {
                    // 같은 요일이 없으면 새 주의 첫날(월요일)로 이동
                    state.selectedDate = YearMonthDay(date: newWeekStart)
                }

                // 새 주의 선택된 날짜가 캐시에 있는지 확인
                if state.dailyRecords[state.selectedDate] != nil {
                    // 캐시 히트: fetch 생략
                    AppLogger.dailyDetail.info("캐시 히트 - 날짜: \(state.selectedDate), fetch 생략")
                    return .none
                } else {
                    // 캐시 미스: 주 단위 fetch
                    AppLogger.dailyDetail.notice("캐시 미스 - 날짜: \(state.selectedDate), 주 단위 fetch 시작")
                    return .send(.fetchWeekRecords)
                }

            case .fetchWeekRecords:
                guard let weekStart = state.currentWeekDates.first,
                      let weekEnd = state.currentWeekDates.last else {
                    return .send(.weekRecordsFetchFailed(.emptyWeekDates))
                }

                state.isLoading = true
                state.error = nil
                AppLogger.dailyDetail.debug("fetchWeekRecords 시작")

                return .run { send in
                    do {
                        let startDate = weekStart.toDate()
                        let endDate = weekEnd.toDate()
                        try await healthKitClient.ensureAuthorizationIfNeeded()
                        async let healthKitDatas = try await healthKitClient.fetchRunningDataBetweenDates(startDate, endDate)
                        async let runningRecords = try await runningRecordClient.fetchRecords(startDate, endDate)
                        let groupedHealthKitDatas = try await Dictionary(grouping: healthKitDatas, by: { $0.yearMonthDay })
                        let groupedRunningRecords = try await Dictionary(grouping: runningRecords, by: { $0.yearMonthDay })

                        await send(.healthKitDatasFetched(groupedHealthKitDatas))
                        await send(.runningRecordsFetched(groupedRunningRecords))
                        await send(.mergeDailyRecords(healthKitDatas: groupedHealthKitDatas, runningRecords: groupedRunningRecords))
                    } catch {
                        let errorMessage = error.localizedDescription
                        await send(.weekRecordsFetchFailed(.fetchFailed(underlyingError: errorMessage)))
                    }
                }

            case let .healthKitDatasFetched(healthKitDatas):
                state.healthKitDatas.merge(healthKitDatas) { _, new in new }
                return .none

            case let .runningRecordsFetched(runningRecords):
                state.runningRecords.merge(runningRecords) { _, new in new }
                return .none

            case let .mergeDailyRecords(healthKitDatas, runningRecords):
                AppLogger.dailyDetail.debug("mergeCachedRecords 시작")

                // currentWeekDates의 모든 날짜에 대해 DailyRecord 생성
                for yearMonthDay in state.currentWeekDates {
                    let savedRecords = runningRecords[yearMonthDay] ?? []
                    let healthKitRecords = healthKitDatas[yearMonthDay] ?? []

                    // HealthKit 데이터 중 저장된 기록과 중복되지 않는 것만 필터링
                    let filteredHealthKitRecords = healthKitRecords.filter { healthKitData in
                        !savedRecords.contains(where: { $0.startTime == healthKitData.startDate })
                    }
                    let sortedHealthKitRecords = filteredHealthKitRecords.sorted { $0.startDate < $1.startDate }

                    let dailyRecord = DailyRecord(
                        yearMonthDay: yearMonthDay,
                        healthKitDatas: sortedHealthKitRecords,
                        savedRecords: savedRecords
                    )

                    state.dailyRecords[yearMonthDay] = dailyRecord
                }

                state.isLoading = false
                AppLogger.dailyDetail.info("mergeCachedRecords 완료 - 총 캐시 크기: \(state.dailyRecords.count)")

                return .none

            case let .weekRecordsFetchFailed(error):
                state.isLoading = false
                state.error = error
                let errorMessage = error.localizedDescription
                AppLogger.dailyDetail.error("weekRecordsFetchFailed - error: \(errorMessage)")
                return .none

            case let .mergeCachedRecordsForRefresh(datesToRefresh):
                AppLogger.dailyDetail.debug("mergeCachedRecordsForRefresh 시작 - 날짜 수: \(datesToRefresh.count)")

                // refresh 대상 날짜들에 대해서만 DailyRecord 재생성
                for yearMonthDay in datesToRefresh {
                    let savedRecords = state.runningRecords[yearMonthDay] ?? []
                    let healthKitRecords = state.healthKitDatas[yearMonthDay] ?? []

                    // HealthKit 데이터 중 저장된 기록과 중복되지 않는 것만 필터링
                    let filteredHealthKitRecords = healthKitRecords.filter { healthKitData in
                        !savedRecords.contains(where: { $0.startTime == healthKitData.startDate })
                    }
                    let sortedHealthKitRecords = filteredHealthKitRecords.sorted { $0.startDate < $1.startDate }

                    let dailyRecord = DailyRecord(
                        yearMonthDay: yearMonthDay,
                        healthKitDatas: sortedHealthKitRecords,
                        savedRecords: savedRecords
                    )

                    state.dailyRecords[yearMonthDay] = dailyRecord
                }

                state.isLoading = false
                AppLogger.dailyDetail.info("mergeCachedRecordsForRefresh 완료 - 갱신된 날짜 수: \(datesToRefresh.count), 총 캐시 크기: \(state.dailyRecords.count)")

                return .none

            case .refreshHealthKitForCachedDates:
                // 캐시된 날짜들의 범위를 계산
                let cachedDates = Array(state.dailyRecords.keys).sorted()
                guard let minDate = cachedDates.first,
                      let maxDate = cachedDates.last else {
                    AppLogger.dailyDetail.warning("refreshHealthKitForCachedDates - 캐시된 날짜가 없음")
                    return .none
                }

                state.isLoading = true
                state.error = nil
                AppLogger.dailyDetail.debug("refreshHealthKitForCachedDates 시작 - minDate: \(minDate), maxDate: \(maxDate)")

                return .run { [fetchedRepositoryRecords = state.runningRecords, cachedDates] send in
                    let startTime = Date.now
                    do {
                        try await healthKitClient.ensureAuthorizationIfNeeded()
                        let healthKitDatas = try await healthKitClient.fetchRunningDataBetweenDates(minDate.toDate(), maxDate.toDate())
                        let groupedHealthKitDatas = Dictionary(grouping: healthKitDatas, by: { $0.yearMonthDay })

                        await send(.healthKitDatasFetched(groupedHealthKitDatas))

                        // HealthKit 데이터 fetch 후 자동으로 merge
                        await send(.mergeCachedRecordsForRefresh(cachedDates))
                    } catch {
                        let elapsed = Date.now.timeIntervalSince(startTime)
                        let errorMessage = error.localizedDescription
                        AppLogger.dailyDetail.error("refreshHealthKitForCachedDates 실패 - error: \(errorMessage), elapsed: \(String(format: "%.3f", elapsed))s")
                        await send(.healthKitDataRefreshFailed(.fetchFailed(underlyingError: errorMessage)))
                    }
                }

            case let .healthKitDataRefreshFailed(error):
                state.isLoading = false
                state.error = error
                let errorMessage = error.localizedDescription
                AppLogger.dailyDetail.error("weekRecordsFetchFailed - error: \(errorMessage)")
                return .none

            case let .createRecord(healthKitRecord):
                AppLogger.dailyDetail.debug("showAddRecord - mode: 추가, date: \(state.selectedDate), healthKitData: \(healthKitRecord)")
                state.addRecord = AddRecordFeature.State(
                    existingRecord: nil,
                    healthKitData: healthKitRecord
                )
                return .none

            case let .editRecord(runningRecord):
                AppLogger.dailyDetail.debug("showAddRecord - mode: 수정, date: \(state.selectedDate), runningRecord: \(runningRecord)")
                state.addRecord = AddRecordFeature.State(
                    existingRecord: runningRecord,
                    healthKitData: nil
                )
                return .none

            case .addRecord(.presented(.recordSaved)):
                // 레코드 저장 후 닫힘 - 캐시 무효화 및 새로고침
                AppLogger.dailyDetail.info("recordSaved - 캐시 무효화 및 새로고침 시작")
                state.addRecord = nil
                state.dailyRecords.removeAll()
                return .send(.fetchWeekRecords)

            case .addRecord(.dismiss):
                AppLogger.dailyDetail.debug("addRecord dismiss - 기록 추가/편집 화면 닫힘")
                state.addRecord = nil
                return .none

            case .addRecord:
                return .none

            case .calendarButtonTapped:
                AppLogger.dailyDetail.debug("calendarButtonTapped - 캘린더 화면 표시")
                state.calendar = CalendarFeature.State(selectedDate: state.selectedDate)
                return .none

            case .calendar(.dismiss):
                AppLogger.dailyDetail.debug("calendar dismiss - 캘린더 화면 닫힘")
                state.calendar = nil
                return .none

            case let .calendar(.presented(.delegate(.dailyRecordSaved(dailyRecords)))):
                for (yearMonthDay, dailyRecord) in dailyRecords {
                    state.dailyRecords.updateValue(dailyRecord, forKey: yearMonthDay)
                }
                state.healthKitDatas = state.calendar?.healthKitDatas ?? [:]
                state.runningRecords = state.calendar?.runningRecords ?? [:]
                return .none

            case .calendar(.presented(.navigateToDiary)):
                guard let selectedYearMonthDay = state.calendar?.selectedDate else {
                    AppLogger.dailyDetail.error("navigateToDiary - selectedDate가 없음")
                    state.calendar = nil
                    return .none
                }

                let selectedDate = selectedYearMonthDay
                AppLogger.dailyDetail.info("navigateToDiary - \(selectedYearMonthDay) 날짜로 이동")

                // 선택된 날짜가 속한 주로 즉시 전환
                let newWeekDates = DateHelper.getWeekDates(for: selectedDate.toDate()).map { YearMonthDay(date: $0) }
                state.currentWeekDates = newWeekDates
                state.selectedDate = selectedDate

                // 캘린더 시트 닫기
                state.calendar = nil

                // 캐시 확인 후 필요시 fetch
                if state.dailyRecords[selectedDate] != nil {
                    AppLogger.dailyDetail.debug("navigateToDiary - 캐시 히트, fetch 생략")
                    return .none
                } else {
                    AppLogger.dailyDetail.debug("navigateToDiary - 캐시 미스, 주 단위 fetch 시작")
                    return .send(.fetchWeekRecords)
                }

            case .calendar:
                return .none
            }
        }
        .ifLet(\.$addRecord, action: \.addRecord) {
            AddRecordFeature()
        }
        .ifLet(\.$calendar, action: \.calendar) {
            CalendarFeature()
        }
    }
}
