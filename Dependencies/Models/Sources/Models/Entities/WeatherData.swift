//
//  WeatherData.swift
//  Models
//
//  Created by 김혜지 on 10/31/25.
//

public struct WeatherData: Equatable, Sendable {
    public let temperature: Double  // 기온 (°C)
    public let humidity: Int  // 습도 (%)
    public let windSpeed: Double  // 풍속 (m/s)

    public init(
        temperature: Double,
        humidity: Int,
        windSpeed: Double
    ) {
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
    }
}
