//
//  HealthKitClient.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import ComposableArchitecture
import Foundation
import HealthKitService
import Models

@DependencyClient
struct HealthKitClient {
    var ensureAuthorizationIfNeeded: @MainActor @Sendable () async throws -> Void
    var fetchRunningDataOnDate: @MainActor @Sendable (Date) async throws -> [HealthKitWorkout]
    var fetchRunningDataBetweenDates: @MainActor @Sendable (Date, Date) async throws -> [HealthKitWorkout]
}

extension HealthKitClient: DependencyKey {
    static let liveValue: HealthKitClient = {
        let manager = HealthKitManager()

        return HealthKitClient(
            ensureAuthorizationIfNeeded: {
                try await manager.ensureAuthorizationIfNeeded()
            },
            fetchRunningDataOnDate: { date in
                try await manager.fetchRunningData(for: date)
            },
            fetchRunningDataBetweenDates: { startDate, endDate in
                try await manager.fetchWeeklyRunningData(from: startDate, to: endDate)
            }
        )
    }()

    static let testValue = HealthKitClient(
        ensureAuthorizationIfNeeded: unimplemented("\(Self.self).requestAuthorization"),
        fetchRunningDataOnDate: unimplemented("\(Self.self).fetchRunningData"),
        fetchRunningDataBetweenDates: unimplemented("\(Self.self).fetchWeeklyRunningData")
    )

    static let previewValue = HealthKitClient(
        ensureAuthorizationIfNeeded: {
            // Preview에서는 즉시 성공
        },
        fetchRunningDataOnDate: { _ in
            // Mock 데이터 반환
            [
                HealthKitWorkout(
                    distance: 5.2,
                    duration: 3665,  // 1시간 1분 5초
                    averagePace: "5'30\"",
                    averageHeartRate: 155,
                    averageCadence: 180,
                    activeEnergyBurned: 450.0,
                    runningVerticalOscillation: 8.2,
                    runningGroundContactTime: 240.0,
                    walkingStepLength: 1.1,
                    routeData: nil,
                    startDate: Calendar.current.date(byAdding: .second, value: -3665, to: .now)!,
                    endDate: .now
                )
            ]
        },
        fetchRunningDataBetweenDates: { _, _ in
            // Mock 주간 데이터 반환 (7일)
            (0..<7).map { index in
                // 일부 날짜는 데이터가 없도록 nil 반환
                let duration = Double.random(in: 1800...5400)
                return index % 3 == 0 ? nil : HealthKitWorkout(
                    distance: Double.random(in: 3.0...10.0),
                    duration: duration,
                    averagePace: "5'30\"",
                    averageHeartRate: Int.random(in: 140...170),
                    averageCadence: Int.random(in: 170...185),
                    activeEnergyBurned: Double.random(in: 300...600),
                    runningVerticalOscillation: Double.random(in: 7.0...9.0),
                    runningGroundContactTime: Double.random(in: 230...260),
                    walkingStepLength: Double.random(in: 0.9...1.2),
                    routeData: nil,
                    startDate: Calendar.current.date(byAdding: .second, value: Int(-duration), to: .now)!,
                    endDate: .now
                )
            }.compactMap { $0 }
        }
    )
}

extension DependencyValues {
    var healthKitClient: HealthKitClient {
        get { self[HealthKitClient.self] }
        set { self[HealthKitClient.self] = newValue }
    }
}
