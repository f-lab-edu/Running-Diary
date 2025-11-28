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
    case noHealthKitData

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "기록을 불러올 수 없습니다"
        case .emptyWeekDates:
            return "currentWeekDates가 비어있습니다"
        case .noHealthKitData:
            return "HealthKit 데이터가 없습니다"
        }
    }

    var failureReason: String? {
        switch self {
        case .fetchFailed(let error):
            return error
        case .emptyWeekDates:
            return "currentWeekDates가 비어있습니다"
        case .noHealthKitData:
            return "해당 날짜에 러닝 기록이 없습니다"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "네트워크 연결을 확인하고 다시 시도해주세요"
        case .emptyWeekDates:
            return "데이터를 불러오는 데 실패했습니다"
        case .noHealthKitData:
            return "Apple Health 앱에서 해당 날짜의 러닝 기록을 확인해주세요"
        }
    }
}
