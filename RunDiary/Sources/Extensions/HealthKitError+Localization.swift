//
//  HealthKitError+Localization.swift
//  RunDiary
//
//  Created by 김혜지 on 11/4/25.
//

import Foundation
import HealthKitService

extension HealthKitError: @retroactive LocalizedError {
    public var errorDescription: String? {
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
