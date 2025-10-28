//
//  HealthKitError.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "이 기기에서는 HealthKit을 사용할 수 없습니다."
        case .authorizationFailed:
            return "HealthKit 권한 요청에 실패했습니다. 잠시 후 다시 시도해주세요."
        }
    }
}
