import Foundation

/// 특정 날짜의 러닝 기록을 통합한 모델
/// HealthKit 데이터와 사용자가 저장한 기록을 함께 관리
public struct DailyRecord: Equatable, Sendable {
    /// 기록 날짜
    public let date: Date

    /// HealthKit에서 가져온 러닝 데이터 (옵셔널)
    public let healthKitData: HealthKitRunningData?

    /// Repository에 저장된 사용자 기록 (옵셔널)
    public let savedRecord: RunningRecord?

    public init(
        date: Date,
        healthKitData: HealthKitRunningData? = nil,
        savedRecord: RunningRecord? = nil
    ) {
        self.date = date
        self.healthKitData = healthKitData
        self.savedRecord = savedRecord
    }
}

// MARK: - Computed Properties

extension DailyRecord {
    /// HealthKit 데이터가 존재하는지 여부
    public var hasHealthKitData: Bool {
        healthKitData != nil
    }

    /// 저장된 기록이 존재하는지 여부
    public var hasSavedRecord: Bool {
        savedRecord != nil
    }

    /// 표시할 데이터가 하나라도 있는지 여부
    public var hasAnyData: Bool {
        hasHealthKitData || hasSavedRecord
    }
}
