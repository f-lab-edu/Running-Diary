//
//  HealthKitError.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

enum HealthKitError: LocalizedError, Equatable {
    case notAvailable
    case authorizationFailed
    case dataNotFound

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return L10n.Healthkit.Error.notAvailable
        case .authorizationFailed:
            return L10n.Healthkit.Error.authorizationFailed
        case .dataNotFound:
            return L10n.Healthkit.Error.dataNotFound
        }
    }
}
