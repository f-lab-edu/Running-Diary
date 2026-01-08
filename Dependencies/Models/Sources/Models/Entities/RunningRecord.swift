//
//  RunningRecord.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

public struct RunningRecord: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let yearMonthDay: YearMonthDay
    public let distanceInKilometers: Double
    public let durationInSeconds: TimeInterval  // seconds
    public let averagePace: String  // min/km
    public let averageHeartRate: Int  // bpm
    public let averageCadence: Int  // steps/min
    public let painAreas: [PainArea]
    public let runningStyle: RunninStyle?
    public let condition: RunningCondition
    public let shoes: String?
    public let weather: WeatherData?
    public let difficultyLevel: DifficultyLevel?
    public let routeData: Data?  // HealthKit route data
    public let activeEnergyBurned: Double?          // kcal
    public let runningVerticalOscillation: Double?  // cm
    public let runningGroundContactTime: Double?    // ms
    public let walkingStepLength: Double?           // m
    public let hasMap: Bool
    public let startTime: Date
    public let endTime: Date

    public var distanceInMiles: Double {
        durationInSeconds * 0.621371
    }

    public var formattedDuration: String {
        let hours = Int(durationInSeconds) / 3600
        let minutes = (Int(durationInSeconds) % 3600) / 60
        let seconds = Int(durationInSeconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    public init(
        id: UUID = UUID(),
        yearMonthDay: YearMonthDay,
        distanceInKilometers: Double,
        durationInSeconds: TimeInterval,
        averagePace: String,
        averageHeartRate: Int,
        averageCadence: Int,
        painAreas: [PainArea] = [],
        runningStyle: RunninStyle?,
        condition: RunningCondition = RunningCondition(),
        shoes: String? = nil,
        weather: WeatherData? = nil,
        difficultyLevel: DifficultyLevel? = nil,
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
        self.yearMonthDay = yearMonthDay
        self.distanceInKilometers = distanceInKilometers
        self.durationInSeconds = durationInSeconds
        self.averagePace = averagePace
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.painAreas = painAreas
        self.runningStyle = runningStyle
        self.condition = condition
        self.shoes = shoes
        self.weather = weather
        self.difficultyLevel = difficultyLevel
        self.routeData = routeData
        self.activeEnergyBurned = activeEnergyBurned
        self.runningVerticalOscillation = runningVerticalOscillation
        self.runningGroundContactTime = runningGroundContactTime
        self.walkingStepLength = walkingStepLength
        self.hasMap = hasMap
        self.startTime = startTime
        self.endTime = endTime
    }
}
