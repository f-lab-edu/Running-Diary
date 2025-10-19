//
//  RunningRecord.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

struct RunningRecord: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let distanceInKilometers: Double?
    let averagePace: String?        // min/km
    let averageHeartRate: Int?      // bpm
    let averageCadence: Int?        // steps/min
    let painAreas: [String]
    let runningStyle: String?
    let condition: RunningCondition
    let shoes: String?
    let weather: Weather?
    let satisfaction: Int?          // 1-5
    let routeData: Data?            // HealthKit route data
    let hasMap: Bool

    var distanceInMiles: Double? {
        distanceInKilometers.map { $0 * 0.621371 }
    }

    init(
        id: UUID = UUID(),
        date: Date,
        distanceInKilometers: Double? = nil,
        averagePace: String? = nil,
        averageHeartRate: Int? = nil,
        averageCadence: Int? = nil,
        painAreas: [String] = [],
        runningStyle: String? = nil,
        condition: RunningCondition = RunningCondition(),
        shoes: String? = nil,
        weather: Weather? = nil,
        satisfaction: Int? = nil,
        routeData: Data? = nil,
        hasMap: Bool = false
    ) {
        self.id = id
        self.date = date
        self.distanceInKilometers = distanceInKilometers
        self.averagePace = averagePace
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.painAreas = painAreas
        self.runningStyle = runningStyle
        self.condition = condition
        self.shoes = shoes
        self.weather = weather
        self.satisfaction = satisfaction
        self.routeData = routeData
        self.hasMap = hasMap
    }
}

struct RunningCondition: Equatable {
    let sleep: Int?                 // 수면 시간
    let meal: Bool                  // 식사 여부
    let alcohol: Bool               // 음주 여부
    let memo: String?               // 기타 메모

    init(
        sleep: Int? = nil,
        meal: Bool = false,
        alcohol: Bool = false,
        memo: String? = nil
    ) {
        self.sleep = sleep
        self.meal = meal
        self.alcohol = alcohol
        self.memo = memo
    }
}

struct Weather: Equatable {
    let temperature: Double         // 기온 (°C)
    let humidity: Int               // 습도 (%)
    let windSpeed: Double           // 풍속 (m/s)

    init(
        temperature: Double,
        humidity: Int,
        windSpeed: Double
    ) {
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
    }
}
