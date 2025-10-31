//
//  WeatherError.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

enum WeatherError: LocalizedError, Equatable {
    case invalidResponse
    case networkError
    case apiKeyMissing
    case locationRequired

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return L10n.Weather.Error.invalidResponse
        case .networkError:
            return L10n.Weather.Error.networkError
        case .apiKeyMissing:
            return L10n.Weather.Error.apiKeyMissing
        case .locationRequired:
            return L10n.Weather.Error.locationRequired
        }
    }
}
