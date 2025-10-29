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
    @Attribute(.unique)
    var id: UUID
    var date: Date
    var distance: Double
    var duration: TimeInterval
    var averagePace: String
    var averageHeartRate: Int
    var averageCadence: Int
    var painAreasRawData: String?
    var runningStyleRaw: String?
    var sleepHours: Int?
    var hadMeal: Bool
    var hadAlcohol: Bool
    var memo: String?
    var shoes: String?
    var temperature: Double?
    var humidity: Int?
    var windSpeed: Double?
    var difficultyLevelRaw: Int?
    var routeData: Data?
    var hasMap: Bool

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        distance: Double,
        duration: TimeInterval,
        averagePace: String,
        averageHeartRate: Int,
        averageCadence: Int,
        painAreasRaw: [String] = [],
        runningStyleRaw: String?,
        sleepHours: Int? = nil,
        hadMeal: Bool = false,
        hadAlcohol: Bool = false,
        memo: String? = nil,
        shoes: String? = nil,
        temperature: Double? = nil,
        humidity: Int? = nil,
        windSpeed: Double? = nil,
        difficultyLevelRaw: Int? = nil,
        routeData: Data? = nil,
        hasMap: Bool = false
    ) {
        self.id = id
        self.date = date
        self.distance = distance
        self.duration = duration
        self.averagePace = averagePace
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.runningStyleRaw = runningStyleRaw
        self.sleepHours = sleepHours
        self.hadMeal = hadMeal
        self.hadAlcohol = hadAlcohol
        self.memo = memo
        self.shoes = shoes
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.difficultyLevelRaw = difficultyLevelRaw
        self.routeData = routeData
        self.hasMap = hasMap

        self.painAreasRawData = PainAreasMapper.encodeRaw(painAreasRaw)
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

        // Convert raw values to enums
        let painAreas = PainAreasMapper.decode(painAreasRawData)
        let runningStyle = runningStyleRaw.flatMap { RunninStyle(rawValue: $0) }
        let difficultyLevel = difficultyLevelRaw.flatMap { DifficultyLevel(rawValue: $0) }

        return RunningRecord(
            id: id,
            date: date,
            distanceInKilometers: distance,
            durationInSeconds: duration,
            averagePace: averagePace,
            averageHeartRate: averageHeartRate,
            averageCadence: averageCadence,
            painAreas: painAreas,
            runningStyle: runningStyle,
            condition: condition,
            shoes: shoes,
            weather: weather,
            difficultyLevel: difficultyLevel,
            routeData: routeData,
            hasMap: hasMap
        )
    }

    static func fromDomain(_ record: RunningRecord) -> RunningRecordModel {
        RunningRecordModel(
            id: record.id,
            date: record.date,
            distance: record.distanceInKilometers,
            duration: record.durationInSeconds,
            averagePace: record.averagePace,
            averageHeartRate: record.averageHeartRate,
            averageCadence: record.averageCadence,
            painAreasRaw: record.painAreas.map { $0.rawValue },
            runningStyleRaw: record.runningStyle?.rawValue,
            sleepHours: record.condition.sleep,
            hadMeal: record.condition.meal,
            hadAlcohol: record.condition.alcohol,
            memo: record.condition.memo,
            shoes: record.shoes,
            temperature: record.weather?.temperature,
            humidity: record.weather?.humidity,
            windSpeed: record.weather?.windSpeed,
            difficultyLevelRaw: record.difficultyLevel?.rawValue,
            routeData: record.routeData,
            hasMap: record.hasMap
        )
    }
}

// MARK: - Preview

extension RunningRecordModel {
    private static func date(
        calendar: Calendar = Calendar.current,
        timeZone: TimeZone = TimeZone(identifier: "Asia/Seoul")!,
        year: Int, month: Int, day: Int
    ) -> Date {
        let dateComponent = DateComponents(calendar: calendar, timeZone: timeZone, year: year, month: month, day: day)
        let date = calendar.date(from: dateComponent)
        return date ?? Date.now
    }

    static var preview: RunningRecordModel {
        RunningRecordModel(
            id: UUID(),
            distance: 5.32,
            duration: 1800,
            averagePace: "5'40\"",
            averageHeartRate: 148,
            averageCadence: 172,
            painAreasRaw: ["무릎", "종아리"],
            runningStyleRaw: "Midfoot",
            sleepHours: 7,
            hadMeal: true,
            hadAlcohol: false,
            memo: "상쾌한 아침 러닝이었음. 후반부에 약간 무릎 통증.",
            shoes: "Nike Zoom Fly 5",
            temperature: 18.5,
            humidity: 62,
            windSpeed: 3.2,
            difficultyLevelRaw: 4,
            routeData: nil,
            hasMap: true
        )
    }

    static var previewRecords: [RunningRecordModel] {
        [
            RunningRecordModel(
                id: UUID(),
                date: date(year: 2025, month: 10, day: 15),
                distance: 5.0,
                duration: 1780,
                averagePace: "5'55\"",
                averageHeartRate: 152,
                averageCadence: 170,
                painAreasRaw: ["발목"],
                runningStyleRaw: "Forefoot",
                sleepHours: 6,
                hadMeal: true,
                hadAlcohol: false,
                memo: "기온이 약간 높았지만 페이스 유지에 성공.",
                shoes: "ASICS Metaspeed Sky",
                temperature: 21.0,
                humidity: 58,
                windSpeed: 2.1,
                difficultyLevelRaw: 4,
                routeData: nil,
                hasMap: true
            ),
            RunningRecordModel(
                id: UUID(),
                date: date(year: 2025, month: 10, day: 18),
                distance: 7.8,
                duration: 2600,
                averagePace: "5'20\"",
                averageHeartRate: 155,
                averageCadence: 176,
                painAreasRaw: [],
                runningStyleRaw: "Midfoot",
                sleepHours: 8,
                hadMeal: true,
                hadAlcohol: false,
                memo: "페이스 좋았음. 마지막 1km에서 스퍼트.",
                shoes: "Nike Pegasus 40",
                temperature: 17.2,
                humidity: 65,
                windSpeed: 3.4,
                difficultyLevelRaw: 5,
                routeData: nil,
                hasMap: true
            ),
            RunningRecordModel(
                id: UUID(),
                distance: 3.5,
                duration: 1200,
                averagePace: "5'45\"",
                averageHeartRate: 140,
                averageCadence: 168,
                painAreasRaw: ["허벅지"],
                runningStyleRaw: "Rearfoot",
                sleepHours: 5,
                hadMeal: false,
                hadAlcohol: true,
                memo: "전날 술 때문에 컨디션이 안 좋았음.",
                shoes: "Adidas Adizero Boston 12",
                temperature: 19.5,
                humidity: 70,
                windSpeed: 2.8,
                difficultyLevelRaw: 2,
                routeData: nil,
                hasMap: false
            ),
            RunningRecordModel.preview
        ]
    }
}
