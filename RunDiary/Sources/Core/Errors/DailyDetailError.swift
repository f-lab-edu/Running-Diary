//
//  DailyDetailError.swift
//  RunDiary
//
//  Created by Claude on 10/30/25.
//

import Foundation

/// DailyDetail Feature에서 발생하는 도메인 에러
enum DailyDetailError: LocalizedError, Equatable {
    case fetchFailed(underlyingError: String)
    case emptyWeekDates
    case noHealthKitWorkout

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "기록을 불러올 수 없습니다"
        case .emptyWeekDates:
            return "데이터를 요청한 날짜가 비어있습니다"
        case .noHealthKitWorkout:
            return "HealthKit 데이터가 없습니다"
        }
    }
}
