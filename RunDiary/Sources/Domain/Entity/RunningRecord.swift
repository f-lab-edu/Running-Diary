//
//  RunningRecord.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

struct RunningRecord: Identifiable {
    let id: UUID
    let date: Date
    let distance: Double? // km
    let averagePace: String? // min/km
    let averageHeartRate: Int? // bpm
    let averageCadence: Int? // steps/min
    let painAreas: [String]
    let runningStyle: String?
    let condition: RunningCondition
    let shoes: String?
    let hasMap: Bool

    init(
        id: UUID = UUID(),
        date: Date,
        distance: Double? = nil,
        averagePace: String? = nil,
        averageHeartRate: Int? = nil,
        averageCadence: Int? = nil,
        painAreas: [String] = [],
        runningStyle: String? = nil,
        condition: RunningCondition = RunningCondition(),
        shoes: String? = nil,
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
        self.condition = condition
        self.shoes = shoes
        self.hasMap = hasMap
    }
}

struct RunningCondition {
    let sleep: String?
    let meal: String?
    let alcohol: String?
    let custom: String?

    init(
        sleep: String? = nil,
        meal: String? = nil,
        alcohol: String? = nil,
        custom: String? = nil
    ) {
        self.sleep = sleep
        self.meal = meal
        self.alcohol = alcohol
        self.custom = custom
    }
}
