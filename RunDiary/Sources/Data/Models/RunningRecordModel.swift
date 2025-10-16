//
//  RunningRecordModel.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import SwiftData

@Model
final class RunningRecordModel {
    @Attribute(.unique) var id: UUID
    var date: Date
    var distance: Double?
    var averagePace: String?
    var averageHeartRate: Int?
    var averageCadence: Int?
    var painAreas: [String]
    var runningStyle: String?
    var sleepHours: Int?
    var hadMeal: Bool
    var hadAlcohol: Bool
    var memo: String?
    var shoes: String?
    var temperature: Double?
    var humidity: Int?
    var windSpeed: Double?
    var satisfaction: Int?
    var routeData: Data?
    var hasMap: Bool

    init(
        id: UUID = UUID(),
        date: Date,
        distance: Double? = nil,
        averagePace: String? = nil,
        averageHeartRate: Int? = nil,
        averageCadence: Int? = nil,
        painAreas: [String] = [],
        runningStyle: String? = nil,
        sleepHours: Int? = nil,
        hadMeal: Bool = false,
        hadAlcohol: Bool = false,
        memo: String? = nil,
        shoes: String? = nil,
        temperature: Double? = nil,
        humidity: Int? = nil,
        windSpeed: Double? = nil,
        satisfaction: Int? = nil,
        routeData: Data? = nil,
        hasMap: Bool = false
    ) {
        self.id = id
        self.date = date
        self.distance = distance
        self.averagePace = averagePace
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.painAreas = painAreas
        self.runningStyle = runningStyle
        self.sleepHours = sleepHours
        self.hadMeal = hadMeal
        self.hadAlcohol = hadAlcohol
        self.memo = memo
        self.shoes = shoes
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.satisfaction = satisfaction
        self.routeData = routeData
        self.hasMap = hasMap
    }
}

// MARK: - Conversion Methods

extension RunningRecordModel {
    func toDomain() -> RunningRecord {
        let condition = RunningCondition(
            sleep: sleepHours,
            meal: hadMeal,
            alcohol: hadAlcohol,
            memo: memo
        )

        let weather: Weather?
        if let temp = temperature, let hum = humidity, let wind = windSpeed {
            weather = Weather(
                temperature: temp,
                humidity: hum,
                windSpeed: wind
            )
        } else {
            weather = nil
        }

        return RunningRecord(
            id: id,
            date: date,
            distance: distance,
            averagePace: averagePace,
            averageHeartRate: averageHeartRate,
            averageCadence: averageCadence,
            painAreas: painAreas,
            runningStyle: runningStyle,
            condition: condition,
            shoes: shoes,
            weather: weather,
            satisfaction: satisfaction,
            routeData: routeData,
            hasMap: hasMap
        )
    }

    static func fromDomain(_ record: RunningRecord) -> RunningRecordModel {
        RunningRecordModel(
            id: record.id,
            date: record.date,
            distance: record.distance,
            averagePace: record.averagePace,
            averageHeartRate: record.averageHeartRate,
            averageCadence: record.averageCadence,
            painAreas: record.painAreas,
            runningStyle: record.runningStyle,
            sleepHours: record.condition.sleep,
            hadMeal: record.condition.meal,
            hadAlcohol: record.condition.alcohol,
            memo: record.condition.memo,
            shoes: record.shoes,
            temperature: record.weather?.temperature,
            humidity: record.weather?.humidity,
            windSpeed: record.weather?.windSpeed,
            satisfaction: record.satisfaction,
            routeData: record.routeData,
            hasMap: record.hasMap
        )
    }
}
