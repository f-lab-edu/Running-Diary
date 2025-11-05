//
//  HealthKitCoordinateData.swift
//  Models
//
//  Created by 김혜지 on 11/6/25.
//

public struct HealthKitCoordinateData: Codable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
