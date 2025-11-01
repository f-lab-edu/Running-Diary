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
            return L10n.Error.notAvailable
        case .authorizationFailed:
            return L10n.Error.authorizationFailed
        case .dataNotFound:
            return L10n.Error.dataNotFound
        }
    }
}
