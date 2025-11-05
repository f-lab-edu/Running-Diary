//
//  CalendarError.swift
//  RunDiary
//
//  Created by Claude on 11/3/25.
//

import Foundation

/// Calendar Feature에서 발생하는 도메인 에러
enum CalendarError: LocalizedError, Equatable {
    case fetchFailed(underlyingError: String)
    case dateRangeInvalid

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "캘린더 데이터를 불러올 수 없습니다"
        case .dateRangeInvalid:
            return "잘못된 날짜 범위입니다"
        }
    }

    var failureReason: String? {
        switch self {
        case .fetchFailed(let error):
            return error
        case .dateRangeInvalid:
            return "시작 날짜가 종료 날짜보다 늦습니다"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "네트워크 연결을 확인하고 다시 시도해주세요"
        case .dateRangeInvalid:
            return "날짜 범위를 확인해주세요"
        }
    }
}
