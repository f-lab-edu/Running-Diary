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
        var isLoading: Bool = false
        var error: DailyDetailError? = nil
        var weatherTrademark: WeatherTrademark? = nil
        @Presents var addRecord: AddRecordFeature.State?
        @Presents var calendar: CalendarFeature.State?
        @Presents var settings: SettingsFeature.State?

        var currentDailyRecord: DailyRecord? {
            return dailyRecords[selectedDate]
        }

        init(
            selectedDate: YearMonthDay = .today,
            currentWeekDates: [YearMonthDay] = [],
            cachedRecords: [YearMonthDay: DailyRecord] = [:],
            isLoading: Bool = false,
            addRecord: AddRecordFeature.State? = nil,
            calendar: CalendarFeature.State? = nil,
            settings: SettingsFeature.State? = nil
        ) {
            self.selectedDate = selectedDate
            self.currentWeekDates = currentWeekDates
            self.dailyRecords = cachedRecords
            self.isLoading = isLoading
            self.addRecord = addRecord
            self.calendar = calendar
            self.settings = settings
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case dateSelected(YearMonthDay)
        case weekChanged(offset: Int)
        case fetchWeekRecords
        case weekRecordsFetched([YearMonthDay: DailyRecord])
        case weekRecordsFetchFailed(DailyDetailError)
        case fetchWeatherTrademark
        case weatherTrademarkFetched(WeatherTrademark)
        case createRecord(HealthKitWorkout)
        case editRecord(RunningRecord)
        case addRecord(PresentationAction<AddRecordFeature.Action>)
        case calendarButtonTapped
        case calendar(PresentationAction<CalendarFeature.Action>)
        case settingsButtonTapped
        case settings(PresentationAction<SettingsFeature.Action>)
        case refreshCurrentWeek
        case refreshCompleted
    }

    // MARK: - Dependency

    @Dependency(\.runningRecordClient) var runningRecordClient
    @Dependency(\.weatherClient) var weatherClient
    @Dependency(\.swiftDataClient) var swiftDataClient

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

                // Fetch trademark only if not already loaded
                if state.weatherTrademark == nil {
                    return .merge(
                        .send(.fetchWeekRecords),
                        .send(.fetchWeatherTrademark)
                    )
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
                        let dailyRecords = try await runningRecordClient.fetchData(
                            from: weekStart,
                            to: weekEnd
                        )
                        await send(.weekRecordsFetched(dailyRecords))
                    } catch {
                        let errorMessage = error.localizedDescription
                        await send(.weekRecordsFetchFailed(.fetchFailed(underlyingError: errorMessage)))
                    }
                }

            case let .weekRecordsFetched(dailyRecords):
                state.dailyRecords.merge(dailyRecords) { _, new in new }
                state.isLoading = false
                AppLogger.dailyDetail.info("weekRecordsFetched 완료 - 총 캐시 크기: \(state.dailyRecords.count)")
                return .send(.refreshCompleted)

            case let .weekRecordsFetchFailed(error):
                state.isLoading = false
                state.error = error
                let errorMessage = error.localizedDescription
                AppLogger.dailyDetail.error("weekRecordsFetchFailed - error: \(errorMessage)")
                return .none

            case .fetchWeatherTrademark:
                AppLogger.dailyDetail.debug("fetchWeatherTrademark 시작")

                return .run { send in
                    let trademark = try await weatherClient.fetchTrademark()
                    await send(.weatherTrademarkFetched(trademark))
                }

            case let .weatherTrademarkFetched(trademark):
                state.weatherTrademark = trademark
                AppLogger.dailyDetail.info("weatherTrademarkFetched 완료 - imageURL: \(trademark.imageURL != nil), legalURL: \(trademark.legalPageURL != nil)")
                return .none

            case let .createRecord(healthKitWorkout):
                AppLogger.dailyDetail.debug("showAddRecord - mode: 추가, date: \(state.selectedDate), healthKitWorkout: \(healthKitWorkout)")
                state.addRecord = AddRecordFeature.State(
                    existingRecord: nil,
                    healthKitWorkout: healthKitWorkout
                )
                return .none

            case let .editRecord(runningRecord):
                AppLogger.dailyDetail.debug("showAddRecord - mode: 수정, date: \(state.selectedDate), runningRecord: \(runningRecord)")
                state.addRecord = AddRecordFeature.State(
                    existingRecord: runningRecord,
                    healthKitWorkout: nil
                )
                return .none

            case .addRecord(.presented(.recordSaved)):
                AppLogger.dailyDetail.info("recordSaved - 새로고침 시작")
                state.addRecord = nil
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

            case .settingsButtonTapped:
                AppLogger.dailyDetail.debug("settingsButtonTapped - 설정 화면 표시")
                state.settings = SettingsFeature.State()
                return .none

            case .settings(.dismiss):
                AppLogger.dailyDetail.debug("settings dismiss - 설정 화면 닫힘")
                state.settings = nil
                return .none

            case .settings:
                return .none

            case .refreshCurrentWeek:
                AppLogger.dailyDetail.info("refreshCurrentWeek - 수동 새로고침 시작")

                // 1. Feature cache에서 현재 주 제거
                for date in state.currentWeekDates {
                    state.dailyRecords.removeValue(forKey: date)
                }

                // 2. SwiftData cache clear (Repository의 캐시 제거)
                swiftDataClient.clearCache()
                AppLogger.dailyDetail.debug("SwiftData cache cleared")

                // 3. 다시 fetch (HealthKit은 자동으로 fresh fetch됨)
                return .send(.fetchWeekRecords)

            case .refreshCompleted:
                // UI 피드백 (예: 햅틱, 토스트 등)
                return .none
            }
        }
        .ifLet(\.$addRecord, action: \.addRecord) {
            AddRecordFeature()
        }
        .ifLet(\.$calendar, action: \.calendar) {
            CalendarFeature()
        }
        .ifLet(\.$settings, action: \.settings) {
            SettingsFeature()
        }
    }
}
