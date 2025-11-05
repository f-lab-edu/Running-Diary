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
    var fetchRunningData: @MainActor @Sendable (Date) async throws -> HealthKitRunningData?
}

extension HealthKitClient: DependencyKey {
    static let liveValue: HealthKitClient = {
        let manager = HealthKitManager()

        return HealthKitClient(
            ensureAuthorizationIfNeeded: {
                try await manager.ensureAuthorizationIfNeeded()
            },
            fetchRunningData: { date in
                try await manager.fetchRunningData(for: date)
            }
        )
    }()

    static let testValue = HealthKitClient(
        ensureAuthorizationIfNeeded: unimplemented("\(Self.self).requestAuthorization"),
        fetchRunningData: unimplemented("\(Self.self).fetchRunningData")
    )

    static let previewValue = HealthKitClient(
        ensureAuthorizationIfNeeded: {
            // Preview에서는 즉시 성공
        },
        fetchRunningData: { _ in
            // Mock 데이터 반환
            HealthKitRunningData(
                distance: 5.2,
                duration: 3665,  // 1시간 1분 5초
                averagePace: "5'30\"",
                averageHeartRate: 155,
                averageCadence: 180,
                routeData: nil,
                startDate: nil,
                endDate: nil
            )
        }
    )
}

extension DependencyValues {
    var healthKitClient: HealthKitClient {
        get { self[HealthKitClient.self] }
        set { self[HealthKitClient.self] = newValue }
    }
}
