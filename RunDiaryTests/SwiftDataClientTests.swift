//
//  RunningRecordClientTests.swift
//  RunDiaryTests
//
//  Created by Claude on 10/23/25.
//

import Foundation
import Models
import Testing

@testable import RunDiary

@Suite("SwiftDataClient")
struct SwiftDataClientTests {

  // MARK: - Test Helpers

  private func makeYearMonthDay(year: Int = 2025, month: Int = 11, day: Int = 27) -> YearMonthDay {
    YearMonthDay(year: year, month: month, day: day)
  }

  private func makeDate(year: Int = 2025, month: Int = 11, day: Int = 27, hour: Int = 9, minute: Int = 0) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components)!
  }

  // MARK: - fetch Tests

  @Test("fetch: 특정 날짜의 기록 조회 성공")
  @MainActor
  func fetchReturnsRecordForDate() async throws {
    let testDate = makeYearMonthDay()
    let startTime = makeDate()
    let endTime = startTime.addingTimeInterval(1800)

    let expectedRecord = RunningRecord(
      yearMonthDay: testDate,
      distanceInKilometers: 5.2,
      durationInSeconds: 1800,
      averagePace: "5'46\"",
      averageHeartRate: 150,
      averageCadence: 170,
      runningStyle: .midfoot,
      condition: RunningCondition(meal: true, alcohol: false),
      startTime: startTime,
      endTime: endTime
    )

    let client = SwiftDataClient(
      fetch: { date in
        #expect(Calendar.current.isDate(date, inSameDayAs: testDate.toDate()))
        return expectedRecord
      },
      fetchRecords: { _, _ in [] },
      save: { _ in },
      update: { _ in },
      delete: { _ in },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    let result = try await client.fetch(testDate.toDate())

    #expect(result != nil)
    #expect(result?.id == expectedRecord.id)
    #expect(result?.yearMonthDay == testDate)
    #expect(result?.distanceInKilometers == 5.2)
    #expect(result?.durationInSeconds == 1800)
    #expect(result?.averagePace == "5'46\"")
    #expect(result?.averageHeartRate == 150)
    #expect(result?.averageCadence == 170)
    #expect(result?.runningStyle == .midfoot)
  }

  @Test("fetch: 기록이 없을 때 nil 반환")
  @MainActor
  func fetchReturnsNilWhenNoRecord() async throws {
    let testDate = makeYearMonthDay()

    let client = SwiftDataClient(
      fetch: { date in
        #expect(Calendar.current.isDate(date, inSameDayAs: testDate.toDate()))
        return nil
      },
      fetchRecords: { _, _ in [] },
      save: { _ in },
      update: { _ in },
      delete: { _ in },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    let result = try await client.fetch(testDate.toDate())
    #expect(result == nil)
  }

  @Test("fetch: 에러 발생 시 throw")
  @MainActor
  func fetchThrowsErrorOnFailure() async throws {
    enum TestError: Error {
      case fetchFailed
    }

    let client = SwiftDataClient(
      fetch: { _ in
        throw TestError.fetchFailed
      },
      fetchRecords: { _, _ in [] },
      save: { _ in },
      update: { _ in },
      delete: { _ in },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    await #expect(throws: TestError.fetchFailed) {
      try await client.fetch(Date.now)
    }
  }

  // MARK: - fetchRecords Tests

  @Test("fetchRecords: 날짜 범위의 여러 기록 조회")
  @MainActor
  func fetchRecordsReturnsMultipleRecords() async throws {
    let startDate = makeDate()
    let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

    let day1 = makeYearMonthDay()
    let day2 = makeYearMonthDay(day: 30)

    let time1Start = makeDate()
    let time1End = time1Start.addingTimeInterval(1500)
    let time2Start = makeDate(day: 30)
    let time2End = time2Start.addingTimeInterval(2250)

    let expectedRecords = [
      RunningRecord(
        yearMonthDay: day1,
        distanceInKilometers: 5.0,
        durationInSeconds: 1500,
        averagePace: "5'00\"",
        averageHeartRate: 145,
        averageCadence: 165,
        runningStyle: .forefoot,
        condition: RunningCondition(meal: true, alcohol: false),
        startTime: time1Start,
        endTime: time1End
      ),
      RunningRecord(
        yearMonthDay: day2,
        distanceInKilometers: 7.5,
        durationInSeconds: 2250,
        averagePace: "5'00\"",
        averageHeartRate: 150,
        averageCadence: 170,
        runningStyle: .midfoot,
        condition: RunningCondition(meal: true, alcohol: false),
        startTime: time2Start,
        endTime: time2End
      ),
    ]

    let client = SwiftDataClient(
      fetch: { _ in nil },
      fetchRecords: { start, end in
        #expect(Calendar.current.isDate(start, inSameDayAs: startDate))
        #expect(Calendar.current.isDate(end, inSameDayAs: endDate))
        return expectedRecords
      },
      save: { _ in },
      update: { _ in },
      delete: { _ in },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    let result = try await client.fetchRecords(startDate, endDate)

    #expect(result.count == 2)
    #expect(result[0].distanceInKilometers == 5.0)
    #expect(result[0].runningStyle == .forefoot)
    #expect(result[1].distanceInKilometers == 7.5)
    #expect(result[1].runningStyle == .midfoot)
  }

  @Test("fetchRecords: 기록이 없을 때 빈 배열 반환")
  @MainActor
  func fetchRecordsReturnsEmptyArray() async throws {
    let startDate = makeDate()
    let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

    let client = SwiftDataClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in [] },
      save: { _ in },
      update: { _ in },
      delete: { _ in },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    let result = try await client.fetchRecords(startDate, endDate)
    #expect(result.isEmpty)
  }

  @Test("fetchRecords: 날짜 순서가 올바른지 확인")
  @MainActor
  func fetchRecordsVerifiesDateOrder() async throws {
    let startDate = makeDate()
    let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

    let day1 = makeYearMonthDay()
    let day2 = makeYearMonthDay(day: 29)
    let day3 = makeYearMonthDay(month: 12, day: 2)

    let time1 = makeDate()
    let time2 = makeDate(day: 29)
    let time3 = makeDate(month: 12, day: 2)

    let records = [
      RunningRecord(
        yearMonthDay: day1,
        distanceInKilometers: 5.0,
        durationInSeconds: 1500,
        averagePace: "5'00\"",
        averageHeartRate: 145,
        averageCadence: 165,
        runningStyle: .forefoot,
        condition: RunningCondition(meal: true, alcohol: false),
        startTime: time1,
        endTime: time1.addingTimeInterval(1500)
      ),
      RunningRecord(
        yearMonthDay: day2,
        distanceInKilometers: 6.0,
        durationInSeconds: 1800,
        averagePace: "5'00\"",
        averageHeartRate: 148,
        averageCadence: 168,
        runningStyle: .midfoot,
        condition: RunningCondition(meal: false, alcohol: false),
        startTime: time2,
        endTime: time2.addingTimeInterval(1800)
      ),
      RunningRecord(
        yearMonthDay: day3,
        distanceInKilometers: 8.0,
        durationInSeconds: 2400,
        averagePace: "5'00\"",
        averageHeartRate: 152,
        averageCadence: 172,
        runningStyle: .forefoot,
        condition: RunningCondition(meal: true, alcohol: true),
        startTime: time3,
        endTime: time3.addingTimeInterval(2400)
      ),
    ]

    let client = SwiftDataClient(
      fetch: { _ in nil },
      fetchRecords: { start, end in
        #expect(start <= end, "시작 날짜는 종료 날짜보다 이전이어야 합니다")
        return records
      },
      save: { _ in },
      update: { _ in },
      delete: { _ in },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    let result = try await client.fetchRecords(startDate, endDate)

    #expect(result.count == 3)
    for i in 0..<result.count - 1 {
      #expect(result[i].startTime <= result[i + 1].startTime, "기록은 날짜 순으로 정렬되어야 합니다")
    }
  }

  @Test("fetchRecords: 에러 발생 시 throw")
  @MainActor
  func fetchRecordsThrowsErrorOnFailure() async throws {
    enum TestError: Error {
      case fetchFailed
    }

    let client = SwiftDataClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in
        throw TestError.fetchFailed
      },
      save: { _ in },
      update: { _ in },
      delete: { _ in },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    let startDate = makeDate()
    let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

    await #expect(throws: TestError.fetchFailed) {
      try await client.fetchRecords(startDate, endDate)
    }
  }

  // MARK: - save Tests

  @Test("save: 새 기록 저장 성공")
  @MainActor
  func saveStoresNewRecord() async throws {
    let yearMonthDay = makeYearMonthDay()
    let startTime = makeDate()
    let endTime = startTime.addingTimeInterval(3000)

    let newRecord = RunningRecord(
      yearMonthDay: yearMonthDay,
      distanceInKilometers: 10.0,
      durationInSeconds: 3000,
      averagePace: "5'00\"",
      averageHeartRate: 160,
      averageCadence: 180,
      runningStyle: .midfoot,
      condition: RunningCondition(meal: true, alcohol: false),
      startTime: startTime,
      endTime: endTime
    )

    var savedRecord: RunningRecord?

    let client = SwiftDataClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in [] },
      save: { record in
        savedRecord = record
      },
      update: { _ in },
      delete: { _ in },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    try await client.save(newRecord)

    #expect(savedRecord != nil)
    #expect(savedRecord?.id == newRecord.id)
    #expect(savedRecord?.distanceInKilometers == 10.0)
    #expect(savedRecord?.durationInSeconds == 3000)
    #expect(savedRecord?.averageHeartRate == 160)
  }

  @Test("save: 모든 필드가 올바르게 저장되는지 확인")
  @MainActor
  func saveStoresAllFields() async throws {
    let yearMonthDay = makeYearMonthDay()
    let startTime = makeDate()
    let endTime = startTime.addingTimeInterval(2550)

    let newRecord = RunningRecord(
      yearMonthDay: yearMonthDay,
      distanceInKilometers: 8.5,
      durationInSeconds: 2550,
      averagePace: "5'00\"",
      averageHeartRate: 155,
      averageCadence: 175,
      painAreas: [.knee, .ankle],
      runningStyle: .forefoot,
      condition: RunningCondition(meal: false, alcohol: true),
      shoes: nil,
      weather: nil,
      startTime: startTime,
      endTime: endTime
    )

    var savedRecord: RunningRecord?

    let client = SwiftDataClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in [] },
      save: { record in
        savedRecord = record
      },
      update: { _ in },
      delete: { _ in },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    try await client.save(newRecord)

    #expect(savedRecord != nil)
    #expect(savedRecord?.painAreas == [.knee, .ankle])
    #expect(savedRecord?.condition.meal == false)
    #expect(savedRecord?.condition.alcohol == true)
  }

  @Test("save: 에러 발생 시 throw")
  @MainActor
  func saveThrowsErrorOnFailure() async throws {
    enum TestError: Error {
      case saveFailed
    }

    let client = SwiftDataClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in [] },
      save: { _ in
        throw TestError.saveFailed
      },
      update: { _ in },
      delete: { _ in },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    let yearMonthDay = makeYearMonthDay()
    let startTime = makeDate()
    let newRecord = RunningRecord(
      yearMonthDay: yearMonthDay,
      distanceInKilometers: 5.0,
      durationInSeconds: 1500,
      averagePace: "5'00\"",
      averageHeartRate: 150,
      averageCadence: 170,
      runningStyle: .midfoot,
      condition: RunningCondition(meal: true, alcohol: false),
      startTime: startTime,
      endTime: startTime.addingTimeInterval(1500)
    )

    await #expect(throws: TestError.saveFailed) {
      try await client.save(newRecord)
    }
  }

  // MARK: - update Tests

  @Test("update: 기존 기록 업데이트 성공")
  @MainActor
  func updateModifiesExistingRecord() async throws {
    let yearMonthDay = makeYearMonthDay()
    let startTime = makeDate()
    let endTime = startTime.addingTimeInterval(1800)

    let updatedRecord = RunningRecord(
      id: UUID(),
      yearMonthDay: yearMonthDay,
      distanceInKilometers: 6.0,
      durationInSeconds: 1800,
      averagePace: "5'00\"",
      averageHeartRate: 155,
      averageCadence: 175,
      runningStyle: .forefoot,
      condition: RunningCondition(meal: false, alcohol: true),
      startTime: startTime,
      endTime: endTime
    )

    var updated: RunningRecord?

    let client = SwiftDataClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in [] },
      save: { _ in },
      update: { record in
        updated = record
      },
      delete: { _ in },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    try await client.update(updatedRecord)

    #expect(updated != nil)
    #expect(updated?.id == updatedRecord.id)
    #expect(updated?.distanceInKilometers == 6.0)
    #expect(updated?.durationInSeconds == 1800)
    #expect(updated?.condition.meal == false)
    #expect(updated?.condition.alcohol == true)
  }

  @Test("update: 모든 필드 업데이트 확인")
  @MainActor
  func updateModifiesAllFields() async throws {
    let recordId = UUID()
    let yearMonthDay = makeYearMonthDay()
    let startTime = makeDate()
    let endTime = startTime.addingTimeInterval(3600)

    let updatedRecord = RunningRecord(
      id: recordId,
      yearMonthDay: yearMonthDay,
      distanceInKilometers: 12.0,
      durationInSeconds: 3600,
      averagePace: "5'00\"",
      averageHeartRate: 165,
      averageCadence: 185,
      painAreas: [.calf],
      runningStyle: .midfoot,
      condition: RunningCondition(meal: true, alcohol: false),
      shoes: nil,
      weather: nil,
      startTime: startTime,
      endTime: endTime
    )

    var updated: RunningRecord?

    let client = SwiftDataClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in [] },
      save: { _ in },
      update: { record in
        updated = record
      },
      delete: { _ in },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    try await client.update(updatedRecord)

    #expect(updated != nil)
    #expect(updated?.id == recordId)
    #expect(updated?.painAreas == [.calf])
    #expect(updated?.runningStyle == .midfoot)
  }

  @Test("update: 에러 발생 시 throw")
  @MainActor
  func updateThrowsErrorOnFailure() async throws {
    enum TestError: Error {
      case updateFailed
    }

    let client = SwiftDataClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in [] },
      save: { _ in },
      update: { _ in
        throw TestError.updateFailed
      },
      delete: { _ in },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    let yearMonthDay = makeYearMonthDay()
    let startTime = makeDate()
    let record = RunningRecord(
      id: UUID(),
      yearMonthDay: yearMonthDay,
      distanceInKilometers: 5.0,
      durationInSeconds: 1500,
      averagePace: "5'00\"",
      averageHeartRate: 150,
      averageCadence: 170,
      runningStyle: .midfoot,
      condition: RunningCondition(meal: true, alcohol: false),
      startTime: startTime,
      endTime: startTime.addingTimeInterval(1500)
    )

    await #expect(throws: TestError.updateFailed) {
      try await client.update(record)
    }
  }

  // MARK: - delete Tests

  @Test("delete: 기록 삭제 성공")
  @MainActor
  func deleteRemovesRecord() async throws {
    let yearMonthDay = makeYearMonthDay()
    let startTime = makeDate()
    let endTime = startTime.addingTimeInterval(1200)

    let recordToDelete = RunningRecord(
      id: UUID(),
      yearMonthDay: yearMonthDay,
      distanceInKilometers: 3.0,
      durationInSeconds: 1200,
      averagePace: "6'40\"",
      averageHeartRate: 140,
      averageCadence: 160,
      runningStyle: .midfoot,
      condition: RunningCondition(meal: true, alcohol: false),
      startTime: startTime,
      endTime: endTime
    )

    var deletedRecord: RunningRecord?

    let client = SwiftDataClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in [] },
      save: { _ in },
      update: { _ in },
      delete: { record in
        deletedRecord = record
      },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    try await client.delete(recordToDelete)

    #expect(deletedRecord != nil)
    #expect(deletedRecord?.id == recordToDelete.id)
    #expect(deletedRecord?.distanceInKilometers == 3.0)
  }

  @Test("delete: 에러 발생 시 throw")
  @MainActor
  func deleteThrowsErrorOnFailure() async throws {
    enum TestError: Error {
      case deleteFailed
    }

    let client = SwiftDataClient(
      fetch: { _ in nil },
      fetchRecords: { _, _ in [] },
      save: { _ in },
      update: { _ in },
      delete: { _ in
        throw TestError.deleteFailed
      },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    let yearMonthDay = makeYearMonthDay()
    let startTime = makeDate()
    let record = RunningRecord(
      id: UUID(),
      yearMonthDay: yearMonthDay,
      distanceInKilometers: 5.0,
      durationInSeconds: 1500,
      averagePace: "5'00\"",
      averageHeartRate: 150,
      averageCadence: 170,
      runningStyle: .midfoot,
      condition: RunningCondition(meal: true, alcohol: false),
      startTime: startTime,
      endTime: startTime.addingTimeInterval(1500)
    )

    await #expect(throws: TestError.deleteFailed) {
      try await client.delete(record)
    }
  }

  // MARK: - Integration Tests

  @Test("통합: fetch -> update -> fetch 흐름")
  @MainActor
  func integrationFetchUpdateFetch() async throws {
    let testDate = makeDate()
    let originalId = UUID()
    let yearMonthDay = makeYearMonthDay()
    let startTime = makeDate()
    let endTime = startTime.addingTimeInterval(1500)

    var storage: [UUID: RunningRecord] = [
      originalId: RunningRecord(
        id: originalId,
        yearMonthDay: yearMonthDay,
        distanceInKilometers: 5.0,
        durationInSeconds: 1500,
        averagePace: "5'00\"",
        averageHeartRate: 145,
        averageCadence: 165,
        runningStyle: .forefoot,
        condition: RunningCondition(meal: true, alcohol: false),
        startTime: startTime,
        endTime: endTime
      )
    ]

    let client = SwiftDataClient(
      fetch: { date in
        storage.values.first { Calendar.current.isDate($0.yearMonthDay.toDate(), inSameDayAs: date) }
      },
      fetchRecords: { _, _ in Array(storage.values) },
      save: { record in
        storage[record.id] = record
      },
      update: { record in
        storage[record.id] = record
      },
      delete: { record in
        storage.removeValue(forKey: record.id)
      },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    let fetched = try await client.fetch(testDate)
    #expect(fetched != nil)
    #expect(fetched?.distanceInKilometers == 5.0)

    var updatedRecord = fetched!
    let newYearMonthDay = updatedRecord.yearMonthDay
    let newStartTime = updatedRecord.startTime
    let newEndTime = updatedRecord.endTime

    updatedRecord = RunningRecord(
      id: updatedRecord.id,
      yearMonthDay: newYearMonthDay,
      distanceInKilometers: 7.5,
      durationInSeconds: updatedRecord.durationInSeconds,
      averagePace: updatedRecord.averagePace,
      averageHeartRate: updatedRecord.averageHeartRate,
      averageCadence: updatedRecord.averageCadence,
      painAreas: updatedRecord.painAreas,
      runningStyle: updatedRecord.runningStyle,
      condition: updatedRecord.condition,
      shoes: updatedRecord.shoes,
      weather: updatedRecord.weather,
      difficultyLevel: updatedRecord.difficultyLevel,
      routeData: updatedRecord.routeData,
      hasMap: updatedRecord.hasMap,
      startTime: newStartTime,
      endTime: newEndTime
    )

    try await client.update(updatedRecord)

    let fetchedAgain = try await client.fetch(testDate)
    #expect(fetchedAgain?.distanceInKilometers == 7.5)
  }

  @Test("통합: save -> fetchRecords 흐름")
  @MainActor
  func integrationSaveFetchRecords() async throws {
    let startDate = makeDate()
    let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

    var storage: [UUID: RunningRecord] = [:]

    let day1 = makeYearMonthDay()
    let day2 = makeYearMonthDay(day: 30)
    let time1Start = makeDate()
    let time1End = time1Start.addingTimeInterval(1500)
    let time2Start = makeDate(day: 30)
    let time2End = time2Start.addingTimeInterval(2100)

    let client = SwiftDataClient(
      fetch: { date in
        storage.values.first { Calendar.current.isDate($0.yearMonthDay.toDate(), inSameDayAs: date) }
      },
      fetchRecords: { start, end in
        storage.values.filter { $0.startTime >= start && $0.startTime <= end }.sorted { $0.startTime < $1.startTime }
      },
      save: { record in
        storage[record.id] = record
      },
      update: { record in
        storage[record.id] = record
      },
      delete: { record in
        storage.removeValue(forKey: record.id)
      },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    let record1 = RunningRecord(
      yearMonthDay: day1,
      distanceInKilometers: 5.0,
      durationInSeconds: 1500,
      averagePace: "5'00\"",
      averageHeartRate: 145,
      averageCadence: 165,
      runningStyle: .forefoot,
      condition: RunningCondition(meal: true, alcohol: false),
      startTime: time1Start,
      endTime: time1End
    )

    let record2 = RunningRecord(
      yearMonthDay: day2,
      distanceInKilometers: 7.0,
      durationInSeconds: 2100,
      averagePace: "5'00\"",
      averageHeartRate: 150,
      averageCadence: 170,
      runningStyle: .midfoot,
      condition: RunningCondition(meal: false, alcohol: false),
      startTime: time2Start,
      endTime: time2End
    )

    try await client.save(record1)
    try await client.save(record2)

    let records = try await client.fetchRecords(startDate, endDate)
    #expect(records.count == 2)
    #expect(records[0].distanceInKilometers == 5.0)
    #expect(records[1].distanceInKilometers == 7.0)
  }

  @Test("통합: save -> delete -> fetch 흐름")
  @MainActor
  func integrationSaveDeleteFetch() async throws {
    let testDate = makeDate()
    var storage: [UUID: RunningRecord] = [:]

    let yearMonthDay = makeYearMonthDay()
    let startTime = makeDate()
    let endTime = startTime.addingTimeInterval(1800)

    let client = SwiftDataClient(
      fetch: { date in
        storage.values.first { Calendar.current.isDate($0.yearMonthDay.toDate(), inSameDayAs: date) }
      },
      fetchRecords: { _, _ in Array(storage.values) },
      save: { record in
        storage[record.id] = record
      },
      update: { record in
        storage[record.id] = record
      },
      delete: { record in
        storage.removeValue(forKey: record.id)
      },
      clearCache: { },
      clearCacheForMonth: { _ in }
    )

    let newRecord = RunningRecord(
      yearMonthDay: yearMonthDay,
      distanceInKilometers: 6.0,
      durationInSeconds: 1800,
      averagePace: "5'00\"",
      averageHeartRate: 150,
      averageCadence: 170,
      runningStyle: .midfoot,
      condition: RunningCondition(meal: true, alcohol: false),
      startTime: startTime,
      endTime: endTime
    )

    try await client.save(newRecord)

    let fetched = try await client.fetch(testDate)
    #expect(fetched != nil)

    try await client.delete(fetched!)

    let fetchedAgain = try await client.fetch(testDate)
    #expect(fetchedAgain == nil)
  }
}
