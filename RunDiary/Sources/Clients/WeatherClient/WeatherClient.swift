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
import WeatherKitService

@DependencyClient
struct WeatherClient {
    var fetchWeather: @MainActor @Sendable (Date, CLLocationCoordinate2D?) async throws -> WeatherData
    var fetchTrademark: @MainActor @Sendable () async throws -> WeatherTrademark
}

extension WeatherClient: DependencyKey {
    static let liveValue: WeatherClient = {
        let manager = WeatherKitManager()

        return WeatherClient(
            fetchWeather: { date, location in
                try await manager.fetchWeather(for: date, location: location)
            },
            fetchTrademark: {
                try await manager.fetchTrademark()
            }
        )
    }()

    static let testValue = WeatherClient(
        fetchWeather: unimplemented("\(Self.self).fetchWeather"),
        fetchTrademark: unimplemented("\(Self.self).fetchTrademark")
    )

    static let previewValue = WeatherClient(
        fetchWeather: { _, _ in
            WeatherData(
                temperature: 18.5,
                humidity: 60,
                windSpeed: 2.3
            )
        },
        fetchTrademark: {
            WeatherTrademark(imageURL: nil, legalPageURL: nil)
        }
    )
}

extension DependencyValues {
    var weatherClient: WeatherClient {
        get { self[WeatherClient.self] }
        set { self[WeatherClient.self] = newValue }
    }
}
