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
            return "Invalid response from weather API"
        case .networkError:
            return "Network error occurred"
        case .apiKeyMissing:
            return "Weather API key is missing"
        case .locationRequired:
            return "Location is required to fetch weather data"
        }
    }
}
