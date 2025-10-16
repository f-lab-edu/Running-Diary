//
//  MockWeatherManager.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import CoreLocation

final class MockWeatherManager: WeatherManagerProtocol {
    func fetchWeather(for date: Date, location: CLLocationCoordinate2D?) async throws -> Weather {
        // Mock 데이터 반환 (개발/테스트용)
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 지연

        return Weather(
            temperature: Double.random(in: 10...30),
            humidity: Int.random(in: 40...80),
            windSpeed: Double.random(in: 0.5...5.0)
        )
    }
}
