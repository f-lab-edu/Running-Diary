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

public final class WeatherKitManager: WeatherManagerProtocol {
    private let weatherService = WeatherService.shared

    public init() {}

    public func fetchWeather(for date: Date, location: CLLocationCoordinate2D?) async throws -> WeatherData {
        guard let location = location else {
            throw WeatherKitError.missingLocation
        }
        
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let queryStart = date.addingTimeInterval(-1800)
        let queryEnd = date.addingTimeInterval(1800)

        // WeatherKit으로 특정 날짜/시간의 날씨 조회
        let hourlyWeather = try await weatherService.weather(
            for: clLocation,
            including: .hourly(startDate: queryStart, endDate: queryEnd)
        )

        guard let weather = hourlyWeather.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        }) else {
            throw WeatherKitError.dataUnavailable
        }

        return WeatherData(
            temperature: weather.temperature.value,
            humidity: Int(weather.humidity * 100),
            windSpeed: weather.wind.speed.value
        )
    }
}
