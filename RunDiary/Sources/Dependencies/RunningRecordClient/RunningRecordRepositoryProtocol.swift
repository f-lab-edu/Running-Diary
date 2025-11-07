//
//  RunningRecordRepositoryProtocol.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Models

protocol RunningRecordRepositoryProtocol {
    func fetch(for date: Date) async throws -> RunningRecord?
    func fetchRecords(from startDate: Date, to endDate: Date) async throws -> [RunningRecord]
    func save(_ record: RunningRecord) async throws
    func update(_ record: RunningRecord) async throws
    func delete(_ record: RunningRecord) async throws
}
