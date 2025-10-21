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
            return "HealthKit is not available on this device"
        case .authorizationFailed:
            return "HealthKit authorization failed"
        }
    }
}
