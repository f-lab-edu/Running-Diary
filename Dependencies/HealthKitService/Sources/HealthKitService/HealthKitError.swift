//
//  HealthKitError.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

public enum HealthKitError: LocalizedError, Equatable {
    case notAvailable
    case authorizationFailed
    case dataNotFound

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return NSLocalizedString("healthkit.error.not_available", bundle: .module, comment: "")
        case .authorizationFailed:
            return NSLocalizedString("healthkit.error.authorization_failed", bundle: .module, comment: "")
        case .dataNotFound:
            return NSLocalizedString("healthkit.error.data_not_found", bundle: .module, comment: "")
        }
    }
}
