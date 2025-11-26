//
//  RunningRecordClient.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import Dependencies
import DependenciesMacros
import Foundation
import SwiftData
import Models

@DependencyClient
struct RunningRecordClient {
    var fetch: @MainActor @Sendable (Date) async throws -> RunningRecord?
    var fetchRecords: @MainActor @Sendable (Date, Date) async throws -> [RunningRecord]
    var save: @MainActor @Sendable (RunningRecord) async throws -> Void
    var update: @MainActor @Sendable (RunningRecord) async throws -> Void
    var delete: @MainActor @Sendable (RunningRecord) async throws -> Void
}

extension RunningRecordClient: DependencyKey {
    static let liveValue: RunningRecordClient = RunningRecordClient(
        fetch: { _ in
            fatalError("RepositoryClient.fetch must be overridden with live implementation")
        },
        fetchRecords: { _, _ in
            fatalError("RepositoryClient.fetchRecords must be overridden with live implementation")
        },
        save: { _ in
            fatalError("RepositoryClient.save must be overridden with live implementation")
        },
        update: { _ in
            fatalError("RepositoryClient.update must be overridden with live implementation")
        },
        delete: { _ in
            fatalError("RepositoryClient.delete must be overridden with live implementation")
        }
    )

    static let testValue = RunningRecordClient(
        fetch: unimplemented("\(Self.self).fetch"),
        fetchRecords: unimplemented("\(Self.self).fetchRecords"),
        save: unimplemented("\(Self.self).save"),
        update: unimplemented("\(Self.self).update"),
        delete: unimplemented("\(Self.self).delete")
    )

    static let previewValue = RunningRecordClient(
        fetch: { date in
            // RunningRecordModel.previewRecords에서 날짜가 일치하는 레코드 찾기
            let calendar = Calendar.current
            return RunningRecordSwiftData.previewRecords
                .first { calendar.isDate($0.date, inSameDayAs: date) }?
                .toDomain()
        },
        fetchRecords: { startDate, endDate in
            // 날짜 범위에 맞는 레코드들 반환
            RunningRecordSwiftData.previewRecords
                .filter { $0.date >= startDate && $0.date <= endDate }
                .map { $0.toDomain() }
        },
        save: { _ in },
        update: { _ in },
        delete: { _ in }
    )
}

extension DependencyValues {
    var runningRecordClient: RunningRecordClient {
        get { self[RunningRecordClient.self] }
        set { self[RunningRecordClient.self] = newValue }
    }
}

// MARK: - Helper

extension RunningRecordClient {
    static func live(modelContext: ModelContext) -> RunningRecordClient {
        let repository = RunningRecordRepository(modelContext: modelContext)

        return RunningRecordClient(
            fetch: { date in
                try await repository.fetch(for: date)
            },
            fetchRecords: { startDate, endDate in
                try await repository.fetchRecords(from: startDate, to: endDate)
            },
            save: { record in
                try await repository.save(record)
            },
            update: { record in
                try await repository.update(record)
            },
            delete: { record in
                try await repository.delete(record)
            }
        )
    }
}
