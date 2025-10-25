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
            return "Record not found"
        case .saveFailed:
            return "Failed to save record"
        case .updateFailed:
            return "Failed to update record"
        case .deleteFailed:
            return "Failed to delete record"
        }
    }
}
