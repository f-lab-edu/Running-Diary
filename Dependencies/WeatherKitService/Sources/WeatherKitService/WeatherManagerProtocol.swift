//
//  WeatherManagerProtocol.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CoreLocation
import Foundation
import Models

public protocol WeatherManagerProtocol {
    func fetchWeather(for date: Date, location: CLLocationCoordinate2D?) async throws -> WeatherData
}
