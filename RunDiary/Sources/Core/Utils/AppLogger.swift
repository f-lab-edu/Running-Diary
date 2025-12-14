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

    func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        logger.info("[\(fileName):\(line)] \(message)")
    }
    
    func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        logger.debug("[\(fileName):\(line)] \(message)")
    }

    func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        logger.error("[\(fileName):\(line)] \(message)")
    }
    
    func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        logger.warning("[\(fileName):\(line)] \(message)")
    }
    
    func notice(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        logger.notice("[\(fileName):\(line)] \(message)")
    }
    
    func critical(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        logger.critical("[\(fileName):\(line)] \(message)")
    }
    
    func fault(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        logger.fault("[\(fileName):\(line)] \(message)")
    }

    @discardableResult
    func measure<T>(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        block: () -> T
    ) -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = block()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let fileName = (file as NSString).lastPathComponent
        logger.debug("[\(fileName):\(line)] \(String(format: "%.4f", duration))s - \(message)")
        return result
    }

    @discardableResult
    func measureAsync<T>(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        block: () async throws -> T
    ) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let fileName = (file as NSString).lastPathComponent
        logger.debug("[\(fileName):\(line)] \(String(format: "%.4f", duration))s - \(message)")
        return result
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
    
    /// Calendar 기능 관련 로거
    static let calendar = LoggerWrapper(
        subsystem: subsystem,
        category: "Calendar"
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

    /// App 수준 로거
    static let app = LoggerWrapper(
        subsystem: subsystem,
        category: "App"
    )
}
