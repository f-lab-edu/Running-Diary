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
            return String(localized: "healthkit.error.not_available")
        case .authorizationFailed:
            return String(localized: "healthkit.error.authorization_failed")
        }
    }
}
