//
//  HealthKitClientTests.swift
//  RunDiaryTests
//
//  Created by Claude on 10/23/25.
//

import Testing
import Foundation
@testable import RunDiary

@Suite("HealthKitClient")
struct HealthKitClientTests {

    @Test("ensureAuthorizationIfNeeded: 권한 요청 성공")
    func authorizationSucceeds() async throws {
        var authorizationRequested = false

        let client = HealthKitClient(
            ensureAuthorizationIfNeeded: {
                authorizationRequested = true
            },
            fetchRunningData: { _ in nil }
        )

        try await client.ensureAuthorizationIfNeeded()

        #expect(authorizationRequested == true)
    }

    @Test("ensureAuthorizationIfNeeded: 권한 거부 시 에러 발생")
    func authorizationThrowsErrorWhenDenied() async throws {
        struct AuthorizationError: Error {}

        let client = HealthKitClient(
            ensureAuthorizationIfNeeded: {
                throw AuthorizationError()
            },
            fetchRunningData: { _ in nil }
        )

        await #expect(throws: AuthorizationError.self) {
            try await client.ensureAuthorizationIfNeeded()
        }
    }

    @Test("fetchRunningData: 러닝 데이터 조회 성공")
    func fetchRunningDataReturnsData() async throws {
        let testDate = Date()
        let expectedData = HealthKitRunningData(
            distance: 5.2,
            duration: 1800,
            averagePace: "5'30\"",
            averageHeartRate: 155,
            averageCadence: 180,
            routeData: nil
        )

        let client = await HealthKitClient(
            ensureAuthorizationIfNeeded: {},
            fetchRunningData: { date in
//                #expect(Calendar.current.isDate(date, inSameDayAs: testDate))
                return expectedData
            }
        )

        let result = try await client.fetchRunningData(testDate)

        #expect(result != nil)
        #expect(result?.distance == 5.2)
        #expect(result?.duration == 1800)
        #expect(result?.averagePace == "5'30\"")
        #expect(result?.averageHeartRate == 155)
        #expect(result?.averageCadence == 180)
    }

    @Test("fetchRunningData: 데이터가 없을 때 nil 반환")
    func fetchRunningDataReturnsNilWhenNoData() async throws {
        let testDate = Date()

        let client = HealthKitClient(
            ensureAuthorizationIfNeeded: {},
            fetchRunningData: { _ in nil }
        )

        let result = try await client.fetchRunningData(testDate)

        #expect(result == nil)
    }

    @Test("fetchRunningData: 데이터 조회 중 에러 발생")
    func fetchRunningDataThrowsError() async throws {
        struct FetchError: Error {}

        let client = HealthKitClient(
            ensureAuthorizationIfNeeded: {},
            fetchRunningData: { _ in
                throw FetchError()
            }
        )

        await #expect(throws: FetchError.self) {
            try await client.fetchRunningData(Date())
        }
    }

    @Test("fetchRunningData: 부분 데이터만 있는 경우")
    func fetchRunningDataWithPartialData() async throws {
        let testDate = Date()
        let partialData = HealthKitRunningData(
            distance: 3.5,
            duration: nil,
            averagePace: nil,
            averageHeartRate: 145,
            averageCadence: nil,
            routeData: nil
        )

        let client = HealthKitClient(
            ensureAuthorizationIfNeeded: {},
            fetchRunningData: { _ in partialData }
        )

        let result = try await client.fetchRunningData(testDate)

        #expect(result != nil)
        #expect(result?.distance == 3.5)
        #expect(result?.duration == nil)
        #expect(result?.averagePace == nil)
        #expect(result?.averageHeartRate == 145)
        #expect(result?.averageCadence == nil)
    }
}
