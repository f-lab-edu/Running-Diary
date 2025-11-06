//
//  WeatherKitErrorDescription.swift
//  RunDiary
//
//  Created by 김혜지 on 11/6/25.
//

import WeatherKitService

extension WeatherKitError {
    public var errorDescription: String? {
        switch self {
        case .missingLocation:
            return L10n.Weather.Error.locationRequired
        case .dataUnavailable:
            return L10n.Weather.Error.dataUnavailable
        }
    }
}
