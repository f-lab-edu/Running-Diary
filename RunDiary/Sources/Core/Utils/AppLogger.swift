//
//  AppLogger.swift
//  RunDiary
//
//  Created by 김혜지 on 10/17/25.
//

import OSLog

/// Logger wrapper - OSLog import 없이 사용 가능
struct LoggerWrapper {
  private let logger: Logger

  init(subsystem: String, category: String) {
    self.logger = Logger(subsystem: subsystem, category: category)
  }

  func info(_ message: String) {
    logger.info("\(message)")
  }

  func debug(_ message: String) {
    logger.debug("\(message)")
  }

  func error(_ message: String) {
    logger.error("\(message)")
  }

  func warning(_ message: String) {
    logger.warning("\(message)")
  }

  func notice(_ message: String) {
    logger.notice("\(message)")
  }

  func critical(_ message: String) {
    logger.critical("\(message)")
  }

  func fault(_ message: String) {
    logger.fault("\(message)")
  }
}

/// 앱 전역에서 사용하는 Logger 유틸리티
enum AppLogger {
  private static let subsystem = "com.kimhyeji.RunDiary"

  /// DailyDetail 기능 관련 로거
  static let dailyDetail = LoggerWrapper(
    subsystem: subsystem,
    category: "DailyDetail"
  )

  /// AddRecord 기능 관련 로거
  static let addRecord = LoggerWrapper(
    subsystem: subsystem,
    category: "AddRecord"
  )

  /// HealthKit 관련 로거
  static let healthKit = LoggerWrapper(
    subsystem: subsystem,
    category: "HealthKit"
  )

  /// 네트워크 관련 로거
  static let network = LoggerWrapper(
    subsystem: subsystem,
    category: "Network"
  )

  /// 데이터베이스 관련 로거
  static let database = LoggerWrapper(
    subsystem: subsystem,
    category: "Database"
  )

  /// 기타 로거
  static let general = LoggerWrapper(
    subsystem: subsystem,
    category: "General"
  )
}
