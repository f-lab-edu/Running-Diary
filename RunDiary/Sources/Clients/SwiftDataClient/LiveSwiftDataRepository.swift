//
//  LiveSwiftDataRepository.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Models
import SwiftData

final class LiveSwiftDataRepository: SwiftDataRepository {
    private let modelContext: ModelContext
    private var cache: [YearMonthDay: [RunningRecord]] = [:]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchRunningRecord(for date: Date) async throws -> RunningRecord? {
        let startTime = Date.now
        AppLogger.database.debug("fetch 시작 - date: \(date)")

        let yearMonthDay = YearMonthDay(date: date)

        // 1. 캐시 확인
        if let cachedRecords = cache[yearMonthDay] {
            let result = cachedRecords.first
            let elapsed = Date.now.timeIntervalSince(startTime)

            if result != nil {
                AppLogger.database.info("fetch 성공 (cached) - date: \(yearMonthDay), elapsed: \(String(format: "%.3f", elapsed))s")
            } else {
                AppLogger.database.debug("fetch 결과 없음 (cached) - date: \(yearMonthDay), elapsed: \(String(format: "%.3f", elapsed))s")
            }

            return result
        }

        // 2. 캐시 미스: DB 조회
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            AppLogger.database.warning("fetch 실패 - endOfDay 계산 실패")
            return nil
        }

        let predicate = #Predicate<RunningRecordPersistenceModel> { record in
            record.date >= startOfDay && record.date < endOfDay
        }

        let descriptor = FetchDescriptor<RunningRecordPersistenceModel>(
            predicate: predicate
        )

        let models = try modelContext.fetch(descriptor)
        let records = models.map { $0.toDomain() }

        // 3. 캐시에 저장
        cache[yearMonthDay] = records

        let elapsed = Date.now.timeIntervalSince(startTime)
        let result = records.first

        if result != nil {
            AppLogger.database.info("fetch 성공 (DB) - date: \(yearMonthDay), elapsed: \(String(format: "%.3f", elapsed))s")
        } else {
            AppLogger.database.debug("fetch 결과 없음 (DB) - date: \(yearMonthDay), elapsed: \(String(format: "%.3f", elapsed))s")
        }

        return result
    }

    func fetchRunningRecords(from startDate: Date, to endDate: Date) async throws -> [RunningRecord] {
        let startTime = Date.now
        AppLogger.database.debug("fetchRecords 시작 - startDate: \(startDate), endDate: \(endDate)")

        // 1. 요청 범위의 날짜들 추출
        let requestedDates = generateDateRange(from: startDate, to: endDate)

        // 2. 캐시 히트 확인
        let missingDates = requestedDates.filter { !cache.keys.contains($0) }

        // 3. 캐시 미스인 날짜만 DB 조회
        if !missingDates.isEmpty {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: startDate)
            let end = calendar.startOfDay(for: endDate)

            let predicate = #Predicate<RunningRecordPersistenceModel> { record in
                record.date >= start && record.date <= end
            }

            let descriptor = FetchDescriptor<RunningRecordPersistenceModel>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )

            let models = try modelContext.fetch(descriptor)
            let fetchedRecords = models.map { $0.toDomain() }

            // 4. 날짜별로 그룹핑하여 캐시에 저장
            let groupedRecords = Dictionary(grouping: fetchedRecords, by: \.yearMonthDay)
            for date in missingDates {
                cache[date] = groupedRecords[date] ?? []
            }

            AppLogger.database.debug("Cache miss - DB fetch: \(fetchedRecords.count) records")
        } else {
            AppLogger.database.debug("Cache hit - all dates cached")
        }

        // 5. 캐시에서 결과 추출
        let result = requestedDates.flatMap { cache[$0] ?? [] }

        let elapsed = Date.now.timeIntervalSince(startTime)
        AppLogger.database.info("fetchRecords 완료 - count: \(result.count), elapsed: \(String(format: "%.3f", elapsed))s")

        return result
    }

    func saveRunningRecord(_ record: RunningRecord) async throws {
        let startTime = Date.now
        AppLogger.database.debug("save 시작 - recordId: \(record.id), date: \(record.yearMonthDay)")

        let model = RunningRecordPersistenceModel.fromDomain(record)
        modelContext.insert(model)

        do {
            try modelContext.save()

            // 캐시 invalidate
            cache.removeValue(forKey: record.yearMonthDay)
            AppLogger.database.debug("Cache invalidated - date: \(record.yearMonthDay)")

            let elapsed = Date.now.timeIntervalSince(startTime)
            AppLogger.database.info("save 성공 - recordId: \(record.id), elapsed: \(String(format: "%.3f", elapsed))s")
        } catch {
            let elapsed = Date.now.timeIntervalSince(startTime)
            let errorMessage = error.localizedDescription
            AppLogger.database.error("save 실패 - recordId: \(record.id), error: \(errorMessage), elapsed: \(String(format: "%.3f", elapsed))s")
            throw SwiftDataError.saveFailed
        }
    }

    func updateRunningRecord(_ record: RunningRecord) async throws {
        let startTime = Date.now
        AppLogger.database.debug("update 시작 - recordId: \(record.id), date: \(record.yearMonthDay)")

        // 기존 레코드 찾기
        let recordId = record.id
        let predicate = #Predicate<RunningRecordPersistenceModel> { $0.id == recordId }
        let descriptor = FetchDescriptor<RunningRecordPersistenceModel>(
            predicate: predicate
        )

        guard let existingModel = try modelContext.fetch(descriptor).first else {
            AppLogger.database.error("update 실패 - recordId: \(recordId), 기존 레코드를 찾을 수 없음")
            throw SwiftDataError.notFound
        }

        // 업데이트
        existingModel.date = record.yearMonthDay.toDate()
        existingModel.distance = record.distanceInKilometers
        existingModel.duration = record.durationInSeconds
        existingModel.averagePace = record.averagePace
        existingModel.averageHeartRate = record.averageHeartRate
        existingModel.averageCadence = record.averageCadence
        existingModel.painAreasRawData = PainAreasMapper.encode(
            record.painAreas
        )
        existingModel.runningStyleRaw = record.runningStyle?.rawValue
        existingModel.sleepHours = record.condition.sleep
        existingModel.hadMeal = record.condition.meal
        existingModel.hadAlcohol = record.condition.alcohol
        existingModel.memo = record.condition.memo
        existingModel.shoes = record.shoes
        existingModel.temperature = record.weather?.temperature
        existingModel.humidity = record.weather?.humidity
        existingModel.windSpeed = record.weather?.windSpeed
        existingModel.difficultyLevelRaw = record.difficultyLevel?.rawValue
        existingModel.routeData = record.routeData
        existingModel.hasMap = record.hasMap
        existingModel.startTime = record.startTime
        existingModel.endTime = record.endTime

        do {
            try modelContext.save()

            // 캐시 invalidate
            cache.removeValue(forKey: record.yearMonthDay)
            AppLogger.database.debug("Cache invalidated - date: \(record.yearMonthDay)")

            let elapsed = Date.now.timeIntervalSince(startTime)
            AppLogger.database.info("update 성공 - recordId: \(recordId), elapsed: \(String(format: "%.3f", elapsed))s")
        } catch {
            let elapsed = Date.now.timeIntervalSince(startTime)
            let errorMessage = error.localizedDescription
            AppLogger.database.error("update 실패 - recordId: \(recordId), error: \(errorMessage), elapsed: \(String(format: "%.3f", elapsed))s")
            throw SwiftDataError.updateFailed
        }
    }

    func deleteRunningRecord(_ record: RunningRecord) async throws {
        let startTime = Date.now
        AppLogger.database.debug("delete 시작 - recordId: \(record.id)")

        let recordId = record.id
        let predicate = #Predicate<RunningRecordPersistenceModel> { $0.id == recordId }
        let descriptor = FetchDescriptor<RunningRecordPersistenceModel>(
            predicate: predicate
        )

        guard let model = try modelContext.fetch(descriptor).first else {
            AppLogger.database.error("delete 실패 - recordId: \(recordId), 기존 레코드를 찾을 수 없음")
            throw SwiftDataError.notFound
        }

        modelContext.delete(model)

        do {
            try modelContext.save()

            // 캐시 invalidate
            cache.removeValue(forKey: record.yearMonthDay)
            AppLogger.database.debug("Cache invalidated - date: \(record.yearMonthDay)")

            let elapsed = Date.now.timeIntervalSince(startTime)
            AppLogger.database.info("delete 성공 - recordId: \(recordId), elapsed: \(String(format: "%.3f", elapsed))s")
        } catch {
            let elapsed = Date.now.timeIntervalSince(startTime)
            let errorMessage = error.localizedDescription
            AppLogger.database.error("delete 실패 - recordId: \(recordId), error: \(errorMessage), elapsed: \(String(format: "%.3f", elapsed))s")
            throw SwiftDataError.deleteFailed
        }
    }

    // MARK: - Cache Management

    func clearCache() {
        cache.removeAll()
        AppLogger.database.info("Cache cleared - all dates")
    }

    func clearCache(for yearMonth: YearMonth) {
        let datesToRemove = cache.keys.filter { $0.toYearMonth() == yearMonth }
        for date in datesToRemove {
            cache.removeValue(forKey: date)
        }
        AppLogger.database.info("Cache cleared - month: \(yearMonth), dates: \(datesToRemove.count)")
    }

    // MARK: - Helper Methods

    private func generateDateRange(from startDate: Date, to endDate: Date) -> [YearMonthDay] {
        var dates: [YearMonthDay] = []
        let calendar = Calendar.current

        var current = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        while current <= end {
            dates.append(YearMonthDay(date: current))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else {
                break
            }
            current = next
        }

        return dates
    }
}
