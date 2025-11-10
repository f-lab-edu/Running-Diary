import Foundation

/// 특정 날짜의 러닝 기록을 통합한 모델
/// HealthKit 데이터와 사용자가 저장한 기록을 함께 관리
public struct DailyRecord: Equatable, Sendable {
    public let yearMonthDay: YearMonthDay
    public let healthKitRecords: [HealthKitRecord]     // HealthKit에서 가져온 러닝 기록등
    public let savedRecords: [RunningRecord]                // Repository에 저장된 사용자 기록들

    public init(
        yearMonthDay: YearMonthDay,
        healthKitRecords: [HealthKitRecord],
        savedRecords: [RunningRecord]
    ) {
        self.yearMonthDay = yearMonthDay
        self.healthKitRecords = healthKitRecords
        self.savedRecords = savedRecords
    }
}

// MARK: - Computed Properties

extension DailyRecord {
    /// HealthKit 데이터가 존재하는지 여부
    public var hasHealthKitData: Bool {
        !healthKitRecords.isEmpty
    }

    /// 저장된 기록이 존재하는지 여부
    public var hasSavedRecord: Bool {
        !savedRecords.isEmpty
    }

    /// 표시할 데이터가 하나라도 있는지 여부
    public var hasAnyData: Bool {
        hasHealthKitData || hasSavedRecord
    }
}
