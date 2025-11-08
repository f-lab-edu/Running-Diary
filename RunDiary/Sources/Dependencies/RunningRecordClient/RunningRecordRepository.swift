//
//  RunningRecordRepository.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Models
import SwiftData

final class RunningRecordRepository: RunningRecordRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetch(for date: Date) async throws -> RunningRecord? {
        let startTime = Date.now
        AppLogger.database.debug("fetch 시작 - date: \(date)")

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            AppLogger.database.warning("fetch 실패 - endOfDay 계산 실패")
            return nil
        }

        let predicate = #Predicate<RunningRecordModel> { record in
            record.date >= startOfDay && record.date < endOfDay
        }

        let descriptor = FetchDescriptor<RunningRecordModel>(
            predicate: predicate
        )

        let models = try modelContext.fetch(descriptor)

        let elapsed = Date.now.timeIntervalSince(startTime)
        let result = models.first?.toDomain()

        if result != nil {
            AppLogger.database.info("fetch 성공 - date: \(startOfDay), elapsed: \(String(format: "%.3f", elapsed))s")
        } else {
            AppLogger.database.debug("fetch 결과 없음 - date: \(startOfDay), elapsed: \(String(format: "%.3f", elapsed))s")
        }

        return result
    }

    func fetchRecords(from startDate: Date, to endDate: Date) async throws -> [RunningRecord] {
        let startTime = Date.now
        AppLogger.database.debug("fetchRecords 시작 - startDate: \(startDate), endDate: \(endDate)")

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        let predicate = #Predicate<RunningRecordModel> { record in
            record.date >= start && record.date <= end
        }

        let descriptor = FetchDescriptor<RunningRecordModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        let models = try modelContext.fetch(descriptor)

        let elapsed = Date.now.timeIntervalSince(startTime)
        let records = models.map { $0.toDomain() }

        AppLogger.database.info("fetchRecords 성공 - count: \(records.count), elapsed: \(String(format: "%.3f", elapsed))s")

        return records
    }

    func save(_ record: RunningRecord) async throws {
        let startTime = Date.now
        AppLogger.database.debug("save 시작 - recordId: \(record.id), date: \(record.date)")

        let model = RunningRecordModel.fromDomain(record)
        modelContext.insert(model)

        do {
            try modelContext.save()
            let elapsed = Date.now.timeIntervalSince(startTime)
            AppLogger.database.info("save 성공 - recordId: \(record.id), elapsed: \(String(format: "%.3f", elapsed))s")
        } catch {
            let elapsed = Date.now.timeIntervalSince(startTime)
            let errorMessage = error.localizedDescription
            AppLogger.database.error("save 실패 - recordId: \(record.id), error: \(errorMessage), elapsed: \(String(format: "%.3f", elapsed))s")
            throw RunningRecordError.saveFailed
        }
    }

    func update(_ record: RunningRecord) async throws {
        let startTime = Date.now
        AppLogger.database.debug("update 시작 - recordId: \(record.id), date: \(record.date)")

        // 기존 레코드 찾기
        let recordId = record.id
        let predicate = #Predicate<RunningRecordModel> { $0.id == recordId }
        let descriptor = FetchDescriptor<RunningRecordModel>(
            predicate: predicate
        )

        guard let existingModel = try modelContext.fetch(descriptor).first else {
            AppLogger.database.error("update 실패 - recordId: \(recordId), 기존 레코드를 찾을 수 없음")
            throw RunningRecordError.notFound
        }

        // 업데이트
        existingModel.date = record.date
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
            let elapsed = Date.now.timeIntervalSince(startTime)
            AppLogger.database.info("update 성공 - recordId: \(recordId), elapsed: \(String(format: "%.3f", elapsed))s")
        } catch {
            let elapsed = Date.now.timeIntervalSince(startTime)
            let errorMessage = error.localizedDescription
            AppLogger.database.error("update 실패 - recordId: \(recordId), error: \(errorMessage), elapsed: \(String(format: "%.3f", elapsed))s")
            throw RunningRecordError.updateFailed
        }
    }

    func delete(_ record: RunningRecord) async throws {
        let startTime = Date.now
        AppLogger.database.debug("delete 시작 - recordId: \(record.id)")

        let recordId = record.id
        let predicate = #Predicate<RunningRecordModel> { $0.id == recordId }
        let descriptor = FetchDescriptor<RunningRecordModel>(
            predicate: predicate
        )

        guard let model = try modelContext.fetch(descriptor).first else {
            AppLogger.database.error("delete 실패 - recordId: \(recordId), 기존 레코드를 찾을 수 없음")
            throw RunningRecordError.notFound
        }

        modelContext.delete(model)

        do {
            try modelContext.save()
            let elapsed = Date.now.timeIntervalSince(startTime)
            AppLogger.database.info("delete 성공 - recordId: \(recordId), elapsed: \(String(format: "%.3f", elapsed))s")
        } catch {
            let elapsed = Date.now.timeIntervalSince(startTime)
            let errorMessage = error.localizedDescription
            AppLogger.database.error("delete 실패 - recordId: \(recordId), error: \(errorMessage), elapsed: \(String(format: "%.3f", elapsed))s")
            throw RunningRecordError.deleteFailed
        }
    }
}
