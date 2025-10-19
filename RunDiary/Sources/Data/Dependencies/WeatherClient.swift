//
//  WeatherClient.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import Foundation
import CoreLocation
import ComposableArchitecture

@DependencyClient
struct WeatherClient {
    var fetchWeather: @Sendable (Date, CLLocationCoordinate2D?) async throws -> Weather
}

extension WeatherClient: DependencyKey {
    static let liveValue: WeatherClient = {
        let manager = KMAWeatherManager()

        return WeatherClient(
            fetchWeather: { date, location in
                try await manager.fetchWeather(for: date, location: location)
            }
        )
    }()

    static let testValue = WeatherClient(
        fetchWeather: unimplemented("\(Self.self).fetchWeather")
    )

    static let previewValue = WeatherClient(
        fetchWeather: { _, _ in
            // Mock 날씨 데이터 반환
            Weather(
                temperature: 18.5,
                humidity: 60,
                windSpeed: 2.3
            )
        }
    )
}

extension DependencyValues {
    var weatherClient: WeatherClient {
        get { self[WeatherClient.self] }
        set { self[WeatherClient.self] = newValue }
    }
}
