//
//  HealthKitClientTests.swift
//  RunDiaryTests
//
//  Created by Claude on 10/23/25.
//

import Foundation
import HealthKitService
import Models

import Testing

@testable import RunDiary

@Suite("HealthKitClient")
struct HealthKitClientTests {

  // MARK: - ensureAuthorizationIfNeeded Tests

  @Test("ensureAuthorizationIfNeeded: 권한 요청 성공")
  func authorizationSucceeds() async throws {
    var authorizationRequested = false

    let client = HealthKitClient(
      ensureAuthorizationIfNeeded: {
        authorizationRequested = true
      },
      fetchRunningDataOnDate: { _ in [] },
      fetchRunningDataBetweenDates: { _, _ in [] }
    )

    try await client.ensureAuthorizationIfNeeded()

    #expect(authorizationRequested == true)
  }

  @Test("ensureAuthorizationIfNeeded: 권한 거부 시 에러 발생")
  func authorizationThrowsErrorWhenDenied() async throws {
    let client = HealthKitClient(
      ensureAuthorizationIfNeeded: {
        throw HealthKitError.authorizationFailed
      },
      fetchRunningDataOnDate: { _ in [] },
      fetchRunningDataBetweenDates: { _, _ in [] }
    )

    await #expect(throws: HealthKitError.self) {
      try await client.ensureAuthorizationIfNeeded()
    }
  }

  // MARK: - fetchRunningDataOnDate Tests

  @Test("fetchRunningDataOnDate: 러닝 데이터 조회 성공")
  func fetchRunningDataOnDateReturnsData() async throws {
    let testDate = Date.now
    let expectedData = [
      HealthKitWorkout(
        distance: 5.2,
        duration: 1800,
        averagePace: "5'30\"",
        averageHeartRate: 155,
        averageCadence: 180,
        activeEnergyBurned: 450,
        runningVerticalOscillation: 8.0,
        runningGroundContactTime: 240.0,
        walkingStepLength: 1.1,
        routeData: nil,
        startDate: testDate,
        endDate: Calendar.current.date(byAdding: .second, value: 1800, to: testDate)!
      ),
      HealthKitWorkout(
        distance: 3.5,
        duration: 1200,
        averagePace: "5'42\"",
        averageHeartRate: 148,
        averageCadence: 175,
        activeEnergyBurned: 300,
        runningVerticalOscillation: 8.2,
        runningGroundContactTime: 250.0,
        walkingStepLength: 1.0,
        routeData: nil,
        startDate: Calendar.current.date(byAdding: .hour, value: 3, to: testDate)!,
        endDate: Calendar.current.date(byAdding: .hour, value: 3, to: testDate)!.addingTimeInterval(1200)
      )
    ]

    let client = HealthKitClient(
      ensureAuthorizationIfNeeded: {},
      fetchRunningDataOnDate: { _ in expectedData },
      fetchRunningDataBetweenDates: { _, _ in [] }
    )

    let result = try await client.fetchRunningDataOnDate(testDate)

    #expect(result.count == 2)
    #expect(result[0].distance == 5.2)
    #expect(result[0].duration == 1800)
    #expect(result[0].averagePace == "5'30\"")
    #expect(result[0].averageHeartRate == 155)
    #expect(result[0].averageCadence == 180)
    #expect(result[1].distance == 3.5)
    #expect(result[1].duration == 1200)
  }

  @Test("fetchRunningDataOnDate: 데이터가 없을 때 빈 배열 반환")
  func fetchRunningDataOnDateReturnsEmptyWhenNoData() async throws {
    let testDate = Date.now

    let client = HealthKitClient(
      ensureAuthorizationIfNeeded: {},
      fetchRunningDataOnDate: { _ in [] },
      fetchRunningDataBetweenDates: { _, _ in [] }
    )

    let result = try await client.fetchRunningDataOnDate(testDate)

    #expect(result.isEmpty)
  }

  @Test("fetchRunningDataOnDate: 데이터 조회 중 에러 발생")
  func fetchRunningDataOnDateThrowsError() async throws {
    let client = HealthKitClient(
      ensureAuthorizationIfNeeded: {},
      fetchRunningDataOnDate: { _ in
        throw HealthKitError.notAvailable
      },
      fetchRunningDataBetweenDates: { _, _ in [] }
    )

    await #expect(throws: HealthKitError.self) {
      try await client.fetchRunningDataOnDate(Date.now)
    }
  }

  // MARK: - fetchRunningDataBetweenDates Tests

  @Test("fetchRunningDataBetweenDates: 날짜 범위 러닝 데이터 조회 성공")
  func fetchRunningDataBetweenDatesReturnsData() async throws {
    let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date.now)!
    let endDate = Date.now

    let expectedData = [
      HealthKitWorkout(
        distance: 5.0,
        duration: 1800,
        averagePace: "6'00\"",
        averageHeartRate: 150,
        averageCadence: 178,
        activeEnergyBurned: 400,
        runningVerticalOscillation: 8.0,
        runningGroundContactTime: 240.0,
        walkingStepLength: 1.0,
        routeData: nil,
        startDate: Calendar.current.date(byAdding: .day, value: -5, to: endDate)!,
        endDate: Calendar.current.date(byAdding: .day, value: -5, to: endDate)!.addingTimeInterval(1800)
      ),
      HealthKitWorkout(
        distance: 7.5,
        duration: 2700,
        averagePace: "6'00\"",
        averageHeartRate: 160,
        averageCadence: 182,
        activeEnergyBurned: 600,
        runningVerticalOscillation: 8.2,
        runningGroundContactTime: 235.0,
        walkingStepLength: 1.1,
        routeData: nil,
        startDate: Calendar.current.date(byAdding: .day, value: -3, to: endDate)!,
        endDate: Calendar.current.date(byAdding: .day, value: -3, to: endDate)!.addingTimeInterval(2700)
      ),
      HealthKitWorkout(
        distance: 10.0,
        duration: 3600,
        averagePace: "6'00\"",
        averageHeartRate: 165,
        averageCadence: 185,
        activeEnergyBurned: 800,
        runningVerticalOscillation: 8.5,
        runningGroundContactTime: 230.0,
        walkingStepLength: 1.2,
        routeData: nil,
        startDate: Calendar.current.date(byAdding: .day, value: -1, to: endDate)!,
        endDate: Calendar.current.date(byAdding: .day, value: -1, to: endDate)!.addingTimeInterval(3600)
      )
    ]

    let client = HealthKitClient(
      ensureAuthorizationIfNeeded: {},
      fetchRunningDataOnDate: { _ in [] },
      fetchRunningDataBetweenDates: { _, _ in expectedData }
    )

    let result = try await client.fetchRunningDataBetweenDates(startDate, endDate)

    #expect(result.count == 3)
    #expect(result[0].distance == 5.0)
    #expect(result[1].distance == 7.5)
    #expect(result[2].distance == 10.0)
  }

  @Test("fetchRunningDataBetweenDates: 데이터가 없을 때 빈 배열 반환")
  func fetchRunningDataBetweenDatesReturnsEmptyWhenNoData() async throws {
    let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date.now)!
    let endDate = Date.now

    let client = HealthKitClient(
      ensureAuthorizationIfNeeded: {},
      fetchRunningDataOnDate: { _ in [] },
      fetchRunningDataBetweenDates: { _, _ in [] }
    )

    let result = try await client.fetchRunningDataBetweenDates(startDate, endDate)

    #expect(result.isEmpty)
  }

  @Test("fetchRunningDataBetweenDates: 데이터 조회 중 에러 발생")
  func fetchRunningDataBetweenDatesThrowsError() async throws {
    let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date.now)!
    let endDate = Date.now

    let client = HealthKitClient(
      ensureAuthorizationIfNeeded: {},
      fetchRunningDataOnDate: { _ in [] },
      fetchRunningDataBetweenDates: { _, _ in
        throw HealthKitError.notAvailable
      }
    )

    await #expect(throws: HealthKitError.self) {
      try await client.fetchRunningDataBetweenDates(startDate, endDate)
    }
  }

  @Test("fetchRunningDataBetweenDates: 날짜 범위가 역순일 때")
  func fetchRunningDataBetweenDatesWithReversedDates() async throws {
    let startDate = Date.now
    let endDate = Calendar.current.date(byAdding: .day, value: -7, to: Date.now)!

    let client = HealthKitClient(
      ensureAuthorizationIfNeeded: {},
      fetchRunningDataOnDate: { _ in [] },
      fetchRunningDataBetweenDates: { _, _ in [] }
    )

    let result = try await client.fetchRunningDataBetweenDates(startDate, endDate)

    #expect(result.isEmpty)
  }
}
