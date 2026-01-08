//
//  SwiftDataRepository.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Models

protocol SwiftDataRepository {
    func fetchRunningRecord(for date: Date) async throws -> RunningRecord?
    func fetchRunningRecords(from startDate: Date, to endDate: Date) async throws -> [RunningRecord]
    func saveRunningRecord(_ record: RunningRecord) async throws
    func updateRunningRecord(_ record: RunningRecord) async throws
    func deleteRunningRecord(_ record: RunningRecord) async throws
    func clearCache()
    func clearCache(for yearMonth: YearMonth)
}
