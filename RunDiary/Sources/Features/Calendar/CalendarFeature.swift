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
        var startDate: Date
        var endDate: Date
        var recordsByDate: [Date: RunningRecord?] = [:]
        var monthlyTotals: [String: Double] = [:]
        var isLoading: Bool = false
        var error: CalendarError?

        init(
            startDate: Date? = nil,
            endDate: Date? = nil
        ) {
            let calendar = Calendar.current
            let today = Date()
            self.startDate = startDate ?? calendar.date(byAdding: .year, value: -1, to: today)!
            self.endDate = endDate ?? calendar.date(byAdding: .month, value: 1, to: today)!
        }

        /// 특정 날짜의 기록 조회
        func record(for date: Date) -> RunningRecord? {
            let normalizedDate = Calendar.current.startOfDay(for: date)
            return recordsByDate[normalizedDate] ?? nil
        }

        /// 특정 월의 총 거리 조회 (예: "2025-10")
        func totalDistance(for yearMonth: String) -> Double {
            monthlyTotals[yearMonth] ?? 0.0
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case fetchRecords(startDate: Date, endDate: Date)
        case recordsFetchedSuccess([RunningRecord])
        case recordsFetchedFailure(CalendarError)
        case oldestMonthBecameVisible
        case fetchOlderRecords
    }

    // MARK: - Dependency

    @Dependency(\.repositoryClient) var repositoryClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                AppLogger.calendar.debug("onAppear - 캘린더 화면 표시됨")
                // 초기 날짜 범위로 데이터 조회
                let startDate = state.startDate
                let endDate = state.endDate
                AppLogger.calendar.info("초기 날짜 범위 설정 - startDate: \(startDate), endDate: \(endDate)")
                return .send(.fetchRecords(startDate: startDate, endDate: endDate))

            case let .fetchRecords(startDate, endDate):
                // 날짜 범위 유효성 검사
                guard startDate <= endDate else {
                    AppLogger.calendar.error("fetchRecords 실패 - 잘못된 날짜 범위: startDate: \(startDate), endDate: \(endDate)")
                    return .send(.recordsFetchedFailure(.dateRangeInvalid))
                }

                state.isLoading = true
                state.error = nil
                AppLogger.calendar.debug("fetchRecords 시작 - startDate: \(startDate), endDate: \(endDate)")

                return .run { send in
                    let fetchStartTime = Date()
                    do {
                        // 날짜 범위로 기록 조회
                        let records = try await repositoryClient.fetchRecords(startDate, endDate)
                        let elapsed = Date().timeIntervalSince(fetchStartTime)
                        AppLogger.calendar.info("fetchRecords 성공 - count: \(records.count), elapsed: \(String(format: "%.3f", elapsed))s")
                        await send(.recordsFetchedSuccess(records))
                    } catch {
                        let elapsed = Date().timeIntervalSince(fetchStartTime)
                        AppLogger.calendar.error("fetchRecords 실패 - error: \(error.localizedDescription), elapsed: \(String(format: "%.3f", elapsed))s")
                        await send(.recordsFetchedFailure(.fetchFailed(underlyingError: error.localizedDescription)))
                    }
                }

            case let .recordsFetchedSuccess(records):
                state.isLoading = false
                state.error = nil

                let calendar = Calendar.current

                // 1. records를 날짜별로 매핑 (정규화된 날짜를 키로 사용)
                let recordsByDate = Dictionary(uniqueKeysWithValues: records.map { record in
                    (calendar.startOfDay(for: record.date), record)
                })

                // 2. startDate부터 endDate까지 모든 날짜를 순회하며 딕셔너리에 저장
                var currentDate = calendar.startOfDay(for: state.startDate)
                let normalizedEndDate = calendar.startOfDay(for: state.endDate)

                while currentDate <= normalizedEndDate {
                    // 해당 날짜의 기록이 있으면 저장, 없으면 nil 저장
                    if state.recordsByDate[currentDate] == nil {
                        state.recordsByDate[currentDate] = recordsByDate[currentDate]
                    }

                    // 다음 날로 이동
                    guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                        break
                    }
                    currentDate = nextDate
                }

                // 3. 월별 총 거리 계산
                let yearMonthFormatter = DateFormatter()
                yearMonthFormatter.dateFormat = "yyyy-MM"

                // 기존 월별 총계에 새로운 레코드의 거리를 추가
                for record in records {
                    let yearMonth = yearMonthFormatter.string(from: record.date)
                    state.monthlyTotals[yearMonth, default: 0.0] += record.distanceInKilometers
                }

                AppLogger.calendar.info("recordsFetchedSuccess - \(records.count)개 레코드 처리 완료, 총 캐시 크기: \(state.recordsByDate.count), 월별 집계: \(state.monthlyTotals.count)개 월")

                return .none

            case let .recordsFetchedFailure(error):
                state.isLoading = false
                state.error = error
                AppLogger.calendar.error("recordsFetchedFailure - error: \(error.localizedDescription)")
                return .none

            case .oldestMonthBecameVisible:
                AppLogger.calendar.debug("oldestMonthBecameVisible - 가장 오래된 달이 화면에 표시됨")
                return .send(.fetchOlderRecords)

            case .fetchOlderRecords:
                let calendar = Calendar.current
                // 현재 startDate에서 6개월 이전으로 확장
                guard let newStartDate = calendar.date(byAdding: .month, value: -6, to: state.startDate) else {
                    AppLogger.calendar.warning("fetchOlderRecords 실패 - 날짜 계산 오류")
                    return .none
                }

                let oldStartDate = state.startDate
                state.startDate = newStartDate
                AppLogger.calendar.info("fetchOlderRecords - startDate 확장: \(oldStartDate) -> \(newStartDate)")

                // 확장된 범위의 데이터 조회 (newStartDate ~ oldStartDate - 1일)
                guard let fetchEndDate = calendar.date(byAdding: .day, value: -1, to: oldStartDate) else {
                    AppLogger.calendar.warning("fetchOlderRecords 실패 - fetchEndDate 계산 오류")
                    return .none
                }

                return .send(.fetchRecords(startDate: newStartDate, endDate: fetchEndDate))
            }
        }
    }
}
