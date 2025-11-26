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
        var selectedDate: YearMonthDay = YearMonthDay(date: .now)
        var currentWeekDates: [YearMonthDay] = []
        var cachedRecords: [YearMonthDay: DailyRecord] = [:]
        var isLoading: Bool = false
        var error: DailyDetailError?
        @Presents var addRecord: AddRecordFeature.State?
        @Presents var calendar: CalendarFeature.State?

        /// 선택된 날짜의 DailyRecord 조회
        var currentDailyRecord: DailyRecord? {
            return cachedRecords[selectedDate]
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case dateSelected(YearMonthDay)
        case weekChanged(offset: Int)
        case fetchWeekRecords
        case weekRecordsFetchedSuccess([RunningRecord], healthKitData: [HealthKitData])
        case weekRecordsFetchedFailure(DailyDetailError)
        case createRecord(HealthKitData)
        case editRecord(RunningRecord)
        case addRecord(PresentationAction<AddRecordFeature.Action>)
        case calendarButtonTapped
        case calendar(PresentationAction<CalendarFeature.Action>)
    }

    // MARK: - Dependency

    @Dependency(\.runningRecordClient) var runnintRecordClient
    @Dependency(\.healthKitClient) var healthKitClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                AppLogger.dailyDetail.debug("onAppear - 화면 표시됨")
                // 현재 주의 날짜들로 초기화
                if state.currentWeekDates.isEmpty {
                    let today = Date.now
                    state.currentWeekDates = DateHelper.getWeekDates(for: today).map { YearMonthDay(date: $0) }
                    AppLogger.dailyDetail.info("주간 날짜 초기화 완료 - 시작일: \(state.currentWeekDates.first ?? nil)")
                }
                return .send(.fetchWeekRecords)

            case let .dateSelected(date):
                state.selectedDate = date
                AppLogger.dailyDetail.debug("dateSelected - 선택된 날짜: \(date)")

                // 캐시 히트 확인
                if state.cachedRecords[date] != nil {
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
                if state.cachedRecords[state.selectedDate] != nil {
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
                    AppLogger.dailyDetail.warning("fetchWeekRecords 실패 - currentWeekDates가 비어있음")
                    return .none
                }

                state.isLoading = true
                state.error = nil
                AppLogger.dailyDetail.debug("fetchWeekRecords 시작 - weekStart: \(weekStart), weekEnd: \(weekEnd)")

                return .run { send in
                    let startTime = Date.now

                    do {
                        try await healthKitClient.ensureAuthorizationIfNeeded()
                        async let healthKitDataTask = try healthKitClient.fetchRunningDataBetweenDates(weekStart.toDate(), weekEnd.toDate())
                        async let repositoryDataTask = try runnintRecordClient.fetchRecords(weekStart.toDate(), weekEnd.toDate())

                        let healthKitData = try await healthKitDataTask
                        let repositoryData = try await repositoryDataTask

                        let elapsed = Date.now.timeIntervalSince(startTime)
                        AppLogger.dailyDetail.info("fetchWeekRecords 성공 - HealthKit: \(healthKitData.count), Repository: \(repositoryData.count), elapsed: \(String(format: "%.3f", elapsed))s")

                        await send(.weekRecordsFetchedSuccess(repositoryData, healthKitData: healthKitData))
                    } catch {
                        let elapsed = Date.now.timeIntervalSince(startTime)
                        let errorMessage = error.localizedDescription
                        AppLogger.dailyDetail.error("fetchWeekRecords 실패 - error: \(errorMessage), elapsed: \(String(format: "%.3f", elapsed))s")
                        await send(.weekRecordsFetchedFailure(.fetchFailed(underlyingError: errorMessage)))
                    }
                }

            case let .weekRecordsFetchedSuccess(records, healthKitRecords):
                state.isLoading = false
                state.error = nil

                // currentWeekDates의 모든 날짜에 대해 DailyRecord 생성 후 캐시에 저장
                for yearMonthDay in state.currentWeekDates {
                    let savedRecords = records.filter { $0.yearMonthDay == yearMonthDay }
                    let filteredHealthKitRecords = healthKitRecords.filter { record in
                        let isTodayRecord = record.startDate.toYearMonthDay == yearMonthDay
                        let didWriteDiary = savedRecords.contains(where: { $0.startTime == record.startDate })
                        return isTodayRecord && !didWriteDiary
                    }
                    let sortedHealthKitRecords = filteredHealthKitRecords.compactMap { $0 }.sorted { $0.startDate < $1.startDate }

                    let dailyRecord = DailyRecord(
                        yearMonthDay: yearMonthDay,
                        healthKitDatas: sortedHealthKitRecords,
                        savedRecords: savedRecords
                    )

                    state.cachedRecords[yearMonthDay] = dailyRecord
                }

                AppLogger.dailyDetail.info("weekRecordsFetchedSuccess - Repository: \(records.count)개, 총 캐시 크기: \(state.cachedRecords.count)")

                return .none

            case let .weekRecordsFetchedFailure(error):
                state.isLoading = false
                state.error = error
                let errorMessage = error.localizedDescription
                AppLogger.dailyDetail.error("weekRecordsFetchedFailure - error: \(errorMessage)")
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
                state.cachedRecords.removeAll()
                return .send(.fetchWeekRecords)

            case .addRecord(.dismiss):
                // 닫기
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
                if state.cachedRecords[selectedDate] != nil {
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
