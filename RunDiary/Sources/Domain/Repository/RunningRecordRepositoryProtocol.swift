//
//  RunningRecordRepositoryProtocol.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

protocol RunningRecordRepositoryProtocol {
    func fetch(for date: Date) async throws -> RunningRecord?
    func fetchRecords(from startDate: Date, to endDate: Date) async throws -> [RunningRecord]
    func save(_ record: RunningRecord) async throws
    func update(_ record: RunningRecord) async throws
    func delete(_ record: RunningRecord) async throws
}

enum RepositoryError: LocalizedError {
    case notFound
    case saveFailed
    case updateFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .notFound:
            return String(localized: "repository.error.not_found")
        case .saveFailed:
            return String(localized: "repository.error.save_failed")
        case .updateFailed:
            return String(localized: "repository.error.update_failed")
        case .deleteFailed:
            return String(localized: "repository.error.delete_failed")
        }
    }
}
