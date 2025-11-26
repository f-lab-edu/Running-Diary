//
//  RepositoryClientTests.swift
//  RunDiaryTests
//
//  Created by Claude on 10/23/25.
//

import Foundation
import Models

import Testing

@testable import RunDiary

@Suite("RepositoryClient")
struct RepositoryClientTests {

  @Test("fetch: 특정 날짜의 기록 조회 성공")
  func fetchReturnsRecordForDate() async throws {
    let testDate = Date.now
    let expectedRecord = RunningRecord(
      date: testDate,
      distanceInKilometers: 5.2,
      durationInSeconds: 1800,
      averagePace: "5'46\"",
      averageHeartRate: 150,
      averageCadence: 170,
      runningStyle: .midfoot,
      condition: RunningCondition(meal: true, alcohol: false)
    )

    let client = RunningRecordClient(
      fetch: { date in
        #expect(Calendar.current.isDate(date, inSameDayAs: testDate))
        return expectedRecord
      },
      fetchRecords: { _, _ in [] },
      save: { _ in },
      update: { _ in },
      delete: { _ in }
    )

    let result = try await client.fetch(testDate)

    #expect(result != nil)
    #expect(result?.distanceInKilometers == 5.2)
    #expect(result?.durationInSeconds == 1800)
  }

  @Test("fetch: 기록이 없을 때 nil 반환")
  func fetchReturnsNilWhenNoRecord() async throws {
    let testDate = Date.now

    let client = RunningRecordClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in [] },
      save: { _ in },
      update: { _ in },
      delete: { _ in }
    )

    let result = try await client.fetch(testDate)

    #expect(result == nil)
  }

  @Test("fetchRecords: 날짜 범위의 여러 기록 조회")
  func fetchRecordsReturnsMultipleRecords() async throws {
    let startDate = Date.now
    let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

    let expectedRecords = [
      RunningRecord(
        date: startDate,
        distanceInKilometers: 5.0,
        durationInSeconds: 1500,
        averagePace: "5'00\"",
        averageHeartRate: 145,
        averageCadence: 165,
        runningStyle: .forefoot,
        condition: RunningCondition(meal: true, alcohol: false)
      ),
      RunningRecord(
        date: Calendar.current.date(byAdding: .day, value: 3, to: startDate)!,
        distanceInKilometers: 7.5,
        durationInSeconds: 2250,
        averagePace: "5'00\"",
        averageHeartRate: 150,
        averageCadence: 170,
        runningStyle: .midfoot,
        condition: RunningCondition(meal: true, alcohol: false)
      ),
    ]

    let client = RunningRecordClient(
      fetch: { _ in nil },
      fetchRecords: { start, end in
        #expect(Calendar.current.isDate(start, inSameDayAs: startDate))
        #expect(Calendar.current.isDate(end, inSameDayAs: endDate))
        return expectedRecords
      },
      save: { _ in },
      update: { _ in },
      delete: { _ in }
    )

    let result = try await client.fetchRecords(startDate, endDate)

    #expect(result.count == 2)
    #expect(result[0].distanceInKilometers == 5.0)
    #expect(result[1].distanceInKilometers == 7.5)
  }

  @Test("fetchRecords: 기록이 없을 때 빈 배열 반환")
  func fetchRecordsReturnsEmptyArray() async throws {
    let startDate = Date.now
    let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

    let client = RunningRecordClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in [] },
      save: { _ in },
      update: { _ in },
      delete: { _ in }
    )

    let result = try await client.fetchRecords(startDate, endDate)

    #expect(result.isEmpty)
  }

  @Test("save: 새 기록 저장")
  func saveStoresNewRecord() async throws {
    let newRecord = RunningRecord(
      date: Date.now,
      distanceInKilometers: 10.0,
      durationInSeconds: 3000,
      averagePace: "5'00\"",
      averageHeartRate: 160,
      averageCadence: 180,
      runningStyle: .midfoot,
      condition: RunningCondition(meal: true, alcohol: false)
    )

    var savedRecord: RunningRecord?

    let client = RunningRecordClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in [] },
      save: { record in
        savedRecord = record
      },
      update: { _ in },
      delete: { _ in }
    )

    try await client.save(newRecord)

    #expect(savedRecord != nil)
    #expect(savedRecord?.distanceInKilometers == 10.0)
  }

  @Test("update: 기존 기록 업데이트")
  func updateModifiesExistingRecord() async throws {
    let updatedRecord = RunningRecord(
      id: UUID(),
      date: Date.now,
      distanceInKilometers: 6.0,
      durationInSeconds: 1800,
      averagePace: "5'00\"",
      averageHeartRate: 155,
      averageCadence: 175,
      runningStyle: .forefoot,
      condition: RunningCondition(meal: false, alcohol: true)
    )

    var updated: RunningRecord?

    let client = RunningRecordClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in [] },
      save: { _ in },
      update: { record in
        updated = record
      },
      delete: { _ in }
    )

    try await client.update(updatedRecord)

    #expect(updated != nil)
    #expect(updated?.id == updatedRecord.id)
    #expect(updated?.distanceInKilometers == 6.0)
    #expect(updated?.condition.meal == false)
    #expect(updated?.condition.alcohol == true)
  }

  @Test("delete: 기록 삭제")
  func deleteRemovesRecord() async throws {
    let recordToDelete = RunningRecord(
      id: UUID(),
      date: Date.now,
      distanceInKilometers: 3.0,
      durationInSeconds: 1200,
      averagePace: "6'40\"",
      averageHeartRate: 140,
      averageCadence: 160,
      runningStyle: .midfoot,
      condition: RunningCondition(meal: true, alcohol: false)
    )

    var deletedRecord: RunningRecord?

    let client = RunningRecordClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in [] },
      save: { _ in },
      update: { _ in },
      delete: { record in
        deletedRecord = record
      }
    )

    try await client.delete(recordToDelete)

    #expect(deletedRecord != nil)
    #expect(deletedRecord?.id == recordToDelete.id)
  }
}
