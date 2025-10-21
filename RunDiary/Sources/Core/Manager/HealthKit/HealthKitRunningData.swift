//
//  HealthKitRunningData.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

struct HealthKitRunningData {
    let distance: Double?           // km
    let averagePace: String?        // min/km
    let averageHeartRate: Int?      // bpm
    let averageCadence: Int?        // spm
    let routeData: Data?
}

struct HealthKitCoordinateData: Codable {
    let latitude: Double
    let longitude: Double
}
