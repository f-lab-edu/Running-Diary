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
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "이 기기에서는 HealthKit을 사용할 수 없습니다."
        case .authorizationFailed:
            return "HealthKit 권한 요청에 실패했습니다. 잠시 후 다시 시도해주세요."
        case .authorizationDenied:
            return "HealthKit 권한이 거부되어 데이터를 가져올 수 없습니다. 설정 앱에서 접근을 허용해주세요."
        }
    }
}
