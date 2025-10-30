//
//  WeatherError.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

enum WeatherError: LocalizedError {
    case invalidResponse
    case networkError
    case apiKeyMissing
    case locationRequired

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return String(localized: "weather.error.invalid_response")
        case .networkError:
            return String(localized: "weather.error.network_error")
        case .apiKeyMissing:
            return String(localized: "weather.error.api_key_missing")
        case .locationRequired:
            return String(localized: "weather.error.location_required")
        }
    }
}
