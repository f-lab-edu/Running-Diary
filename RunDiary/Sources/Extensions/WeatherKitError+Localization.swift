//
//  WeatherKitError+Localization.swift
//  RunDiary
//
//  Created by 김혜지 on 11/6/25.
//

import Foundation
import WeatherKitService

extension WeatherKitError: @retroactive LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingLocation:
            return L10n.Weather.Error.locationRequired.value
        case .dataUnavailable:
            return L10n.Weather.Error.dataUnavailable.value
        }
    }
}
