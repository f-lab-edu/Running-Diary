//
//  HealthKitRunningData.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

public struct HealthKitRunningData: Sendable {
    public let distance: Double?  // km
    public let duration: TimeInterval?  // seconds
    public let averagePace: String?  // min/km
    public let averageHeartRate: Int?  // bpm
    public let averageCadence: Int?  // spm
    public let routeData: Data?
    public let startDate: Date?
    public let endDate: Date?

    public init(
        distance: Double?,
        duration: TimeInterval?,
        averagePace: String?,
        averageHeartRate: Int?,
        averageCadence: Int?,
        routeData: Data?,
        startDate: Date?,
        endDate: Date?
    ) {
        self.distance = distance
        self.duration = duration
        self.averagePace = averagePace
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.routeData = routeData
        self.startDate = startDate
        self.endDate = endDate
    }
}

struct HealthKitCoordinateData: Codable {
    let latitude: Double
    let longitude: Double
}
