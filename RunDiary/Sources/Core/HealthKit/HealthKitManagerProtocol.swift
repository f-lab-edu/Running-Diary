//
//  HealthKitManagerProtocol.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation

protocol HealthKitManagerProtocol {
  func ensureAuthorizationIfNeeded() async throws
  func fetchRunningData(for date: Date) async throws -> HealthKitRunningData?
}
