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

enum RepositoryError: LocalizedError, Equatable {
  case notFound
  case saveFailed
  case updateFailed
  case deleteFailed

  var errorDescription: String? {
    switch self {
    case .notFound:
      return L10n.Repository.Error.notFound
    case .saveFailed:
      return L10n.Repository.Error.saveFailed
    case .updateFailed:
      return L10n.Repository.Error.updateFailed
    case .deleteFailed:
      return L10n.Repository.Error.deleteFailed
    }
  }
}
