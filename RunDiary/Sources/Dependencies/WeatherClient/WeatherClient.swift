//
//  WeatherClient.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import ComposableArchitecture
import CoreLocation
import Foundation
import Models

@DependencyClient
struct WeatherClient {
    var fetchWeather: @MainActor @Sendable (Date, CLLocationCoordinate2D?) async throws -> WeatherData
}

extension WeatherClient: DependencyKey {
    static let liveValue: WeatherClient = {
        let manager = WeatherKitManager()

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
            WeatherData(
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
