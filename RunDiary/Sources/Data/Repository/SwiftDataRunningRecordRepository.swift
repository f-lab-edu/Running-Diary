//
//  SwiftDataRunningRecordRepository.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import SwiftData

final class SwiftDataRunningRecordRepository: RunningRecordRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetch(for date: Date) async throws -> RunningRecord? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }

        let predicate = #Predicate<RunningRecordModel> { record in
            record.date >= startOfDay && record.date < endOfDay
        }

        let descriptor = FetchDescriptor<RunningRecordModel>(predicate: predicate)

        let models = try modelContext.fetch(descriptor)

        return models.first?.toDomain()
    }

    func fetchRecords(from startDate: Date, to endDate: Date) async throws -> [RunningRecord] {
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

        return models.map { $0.toDomain() }
    }

    func save(_ record: RunningRecord) async throws {
        let model = RunningRecordModel.fromDomain(record)
        modelContext.insert(model)

        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.saveFailed
        }
    }

    func update(_ record: RunningRecord) async throws {
        // 기존 레코드 찾기
        let recordId = record.id
        let predicate = #Predicate<RunningRecordModel> { $0.id == recordId }
        let descriptor = FetchDescriptor<RunningRecordModel>(predicate: predicate)

        guard let existingModel = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }

        // 업데이트
        existingModel.date = record.date
        existingModel.distance = record.distanceInKilometers
        existingModel.duration = record.durationInSeconds
        existingModel.averagePace = record.averagePace
        existingModel.averageHeartRate = record.averageHeartRate
        existingModel.averageCadence = record.averageCadence
        existingModel.painAreasRawData = PainAreasMapper.encode(record.painAreas)
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

        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.updateFailed
        }
    }

    func delete(_ record: RunningRecord) async throws {
        let recordId = record.id
        let predicate = #Predicate<RunningRecordModel> { $0.id == recordId }
        let descriptor = FetchDescriptor<RunningRecordModel>(predicate: predicate)

        guard let model = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }

        modelContext.delete(model)

        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.deleteFailed
        }
    }
}
