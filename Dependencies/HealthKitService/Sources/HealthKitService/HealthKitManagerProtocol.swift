//
//  HealthKitManagerProtocol.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Models

public protocol HealthKitManagerProtocol {
    func ensureAuthorizationIfNeeded() async throws
    func fetchRunningData(for date: Date) async throws -> [HealthKitWorkout]
    func fetchWeeklyRunningData(from startDate: Date, to endDate: Date) async throws -> [HealthKitWorkout]
}
