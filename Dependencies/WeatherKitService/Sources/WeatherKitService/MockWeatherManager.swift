//
//  MockWeatherManager.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CoreLocation
import Foundation
import Models

public final class MockWeatherManager: WeatherManagerProtocol {
    public func fetchWeather(for date: Date, location: CLLocationCoordinate2D?) async throws -> WeatherData {
        // location이 없으면 에러 발생
        guard location != nil else {
            throw WeatherKitError.missingLocation
        }

        // Mock 데이터 반환 (개발/테스트용)
        try await Task.sleep(nanoseconds: 500_000_000)  // 0.5초 지연

        return WeatherData(
            temperature: Double.random(in: 10...30),
            humidity: Int.random(in: 40...80),
            windSpeed: Double.random(in: 0.5...5.0)
        )
    }
}
