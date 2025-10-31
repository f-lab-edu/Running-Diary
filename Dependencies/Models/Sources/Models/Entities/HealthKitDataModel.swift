//
//  HealthKitDataModel.swift
//  Models
//
//  Created by 김혜지 on 10/31/25.
//

import CommonFoundation
import Foundation

public struct HealthKitDataModel: Equatable {
    public let distance: Double                  // km
    public let durationInSeconds: TimeInterval   // seconds
    public let averagePace: String               // min/km
    public let averageHeartRate: Int             // bpm
    public let averageCadence: Int               // steps/min
    public let routeData: Data?

    public var formattedDistance: String {
        distance == 0 ? "" : distance.to2f
    }
    public var formattedDuration: String {
        durationInSeconds == 0 ? "" : durationInSeconds.formatted
    }
    public var formattedAverageHeartRate: String {
        averageHeartRate == 0 ? "" : averageHeartRate.toString
    }
    public var formattedAverageCadence: String {
        averageCadence == 0 ? "" : averageCadence.toString
    }

    public init(
        distance: Double,
        durationInSeconds: TimeInterval,
        averagePace: String,
        averageHeartRate: Int,
        averageCadence: Int,
        routeData: Data?
    ) {
        self.distance = distance
        self.durationInSeconds = durationInSeconds
        self.averagePace = averagePace
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.routeData = routeData
    }
}
