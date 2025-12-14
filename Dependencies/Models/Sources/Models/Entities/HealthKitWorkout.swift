//
//  HealthKitWorkout.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CommonFoundation
import Foundation

public struct HealthKitWorkout: Equatable, Identifiable, Sendable {
    public let id = UUID()
    public let yearMonthDay: YearMonthDay
    public let distance: Double         // km
    public let duration: TimeInterval   // seconds
    public let averagePace: String      // min/km
    public let averageHeartRate: Int    // bpm
    public let averageCadence: Int      // spm
    public let routeData: Data?
    public let startDate: Date
    public let endDate: Date

    public var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    public var formattedDistance: String {
        distance == 0 ? "" : distance.to2f
    }

    public var formattedAverageHeartRate: String {
        averageHeartRate == 0 ? "" : averageHeartRate.toString
    }
    
    public var formattedAverageCadence: String {
        averageCadence == 0 ? "" : averageCadence.toString
    }

    public init(
        distance: Double,
        duration: TimeInterval,
        averagePace: String,
        averageHeartRate: Int,
        averageCadence: Int,
        routeData: Data?,
        startDate: Date,
        endDate: Date
    ) {
        self.distance = distance
        self.yearMonthDay = YearMonthDay(date: startDate)
        self.duration = duration
        self.averagePace = averagePace
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.routeData = routeData
        self.startDate = startDate
        self.endDate = endDate
    }

    /// routeData를 [Location] 배열로 디코딩합니다.
    public func decodeRouteData() -> [Location]? {
        guard let routeData = routeData else { return nil }
        return try? JSONDecoder().decode([Location].self, from: routeData)
    }
}
