//
//  RunningRecordPersistenceModel.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import SwiftData

@Model
public final class RunningRecordPersistenceModel {
    @Attribute(.unique)
    public var id: UUID
    public var date: Date
    public var distance: Double
    public var duration: TimeInterval
    public var averagePace: String
    public var averageHeartRate: Int
    public var averageCadence: Int
    public var painAreasRawData: String?
    public var runningStyleRaw: String?
    public var sleepHours: Int?
    public var hadMeal: Bool
    public var hadAlcohol: Bool
    public var memo: String?
    public var shoes: String?
    public var temperature: Double?
    public var humidity: Int?
    public var windSpeed: Double?
    public var difficultyLevelRaw: Int?
    public var routeData: Data?
    public var activeEnergyBurned: Double?
    public var runningVerticalOscillation: Double?
    public var runningGroundContactTime: Double?
    public var walkingStepLength: Double?
    public var hasMap: Bool
    public var startTime: Date
    public var endTime: Date

    public init(
        id: UUID = UUID(),
        date: Date = Date.now,
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
        activeEnergyBurned: Double? = nil,
        runningVerticalOscillation: Double? = nil,
        runningGroundContactTime: Double? = nil,
        walkingStepLength: Double? = nil,
        hasMap: Bool = false,
        startTime: Date,
        endTime: Date
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
        self.activeEnergyBurned = activeEnergyBurned
        self.runningVerticalOscillation = runningVerticalOscillation
        self.runningGroundContactTime = runningGroundContactTime
        self.walkingStepLength = walkingStepLength
        self.hasMap = hasMap
        self.startTime = startTime
        self.endTime = endTime

        self.painAreasRawData = PainAreasMapper.encodeRaw(painAreasRaw)
    }
}

// MARK: - Conversion Methods

public extension RunningRecordPersistenceModel {
    func toDomain() -> RunningRecord {
        let condition = RunningCondition(
            sleep: sleepHours,
            meal: hadMeal,
            alcohol: hadAlcohol,
            memo: memo
        )

        let weather: WeatherData?
        if let temp = temperature, let hum = humidity, let wind = windSpeed {
            weather = WeatherData(
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
            yearMonthDay: YearMonthDay(date: date),
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
            activeEnergyBurned: activeEnergyBurned,
            runningVerticalOscillation: runningVerticalOscillation,
            runningGroundContactTime: runningGroundContactTime,
            walkingStepLength: walkingStepLength,
            hasMap: hasMap,
            startTime: startTime,
            endTime: endTime
        )
    }

    static func fromDomain(_ record: RunningRecord) -> RunningRecordPersistenceModel {
        RunningRecordPersistenceModel(
            id: record.id,
            date: record.yearMonthDay.toDate(),
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
            activeEnergyBurned: record.activeEnergyBurned,
            runningVerticalOscillation: record.runningVerticalOscillation,
            runningGroundContactTime: record.runningGroundContactTime,
            walkingStepLength: record.walkingStepLength,
            hasMap: record.hasMap,
            startTime: record.startTime,
            endTime: record.endTime
        )
    }
}

// MARK: - Preview

public extension RunningRecordPersistenceModel {
    private static func date(
        calendar: Calendar = Calendar.current,
        timeZone: TimeZone = TimeZone(identifier: "Asia/Seoul")!,
        year: Int, month: Int, day: Int
    ) -> Date {
        let dateComponent = DateComponents(
            calendar: calendar, timeZone: timeZone, year: year, month: month, day: day)
        let date = calendar.date(from: dateComponent)
        return date ?? Date.now
    }

    static var preview: RunningRecordPersistenceModel {
        RunningRecordPersistenceModel(
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
            activeEnergyBurned: 450.0,
            runningVerticalOscillation: 8.2,
            runningGroundContactTime: 240.0,
            walkingStepLength: 1.1,
            hasMap: true,
            startTime: .now,
            endTime: Calendar.current.date(byAdding: .second, value: 1800, to: .now)!
        )
    }

    static var previewRecords: [RunningRecordPersistenceModel] {
        [
            RunningRecordPersistenceModel(
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
                activeEnergyBurned: 380.0,
                runningVerticalOscillation: 8.0,
                runningGroundContactTime: 235.0,
                walkingStepLength: 1.0,
                hasMap: true,
                startTime: date(year: 2025, month: 10, day: 15),
                endTime: Calendar.current.date(byAdding: .second, value: 1780, to: date(year: 2025, month: 10, day: 15))!
            ),
            RunningRecordPersistenceModel(
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
                activeEnergyBurned: 620.0,
                runningVerticalOscillation: 8.5,
                runningGroundContactTime: 230.0,
                walkingStepLength: 1.2,
                hasMap: true,
                startTime: date(year: 2025, month: 10, day: 18),
                endTime: Calendar.current.date(byAdding: .second, value: 2600, to: date(year: 2025, month: 10, day: 18))!
            ),
            RunningRecordPersistenceModel(
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
                activeEnergyBurned: 280.0,
                runningVerticalOscillation: 7.5,
                runningGroundContactTime: 250.0,
                walkingStepLength: 0.95,
                hasMap: false,
                startTime: .now,
                endTime: Calendar.current.date(byAdding: .second, value: 1200, to: .now)!
            ),
            RunningRecordPersistenceModel.preview,
        ]
    }
}
