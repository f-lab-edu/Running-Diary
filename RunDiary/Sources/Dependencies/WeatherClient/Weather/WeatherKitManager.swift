//
//  WeatherKitManager.swift
//  RunDiary
//
//  Created by Claude on 2025-11-06.
//

import CoreLocation
import Foundation
import Models
import WeatherKit

final class WeatherKitManager: WeatherManagerProtocol {
    private let weatherService = WeatherService.shared

    func fetchWeather(for date: Date, location: CLLocationCoordinate2D?) async throws -> WeatherData {
        guard let location = location else {
            throw WeatherKitError.missingLocation
        }
        
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)

        // WeatherKit으로 특정 날짜/시간의 날씨 조회
        // 과거 데이터는 historicalAvailability를 확인해야 하지만,
        // 최근 데이터는 weather(for:including:) 사용
        let weather = try await weatherService.weather(
            for: clLocation,
            including: .current
        )

        let currentWeather = weather

        return WeatherData(
            temperature: currentWeather.temperature.value,
            humidity: Int(currentWeather.humidity * 100),
            windSpeed: currentWeather.wind.speed.value
        )
    }
}

enum WeatherKitError: Error {
    case missingLocation
    case dataUnavailable
}
