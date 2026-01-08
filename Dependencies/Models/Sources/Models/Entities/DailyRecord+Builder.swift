//
//  DailyRecord+Builder.swift
//  RunDiary
//
//  Created by Claude on 1/8/26.
//

import Foundation

extension DailyRecord {
    /// HealthKit과 SwiftData를 조합하여 DailyRecord 딕셔너리 생성
    /// - Parameters:
    ///   - healthKitWorkouts: HealthKit에서 가져온 workout 목록
    ///   - savedRecords: SwiftData에 저장된 record 목록
    ///   - dateRange: 생성할 날짜 범위
    /// - Returns: 날짜별로 매핑된 DailyRecord 딕셔너리
    public static func build(
        from healthKitWorkouts: [HealthKitWorkout],
        savedRecords: [RunningRecord],
        dateRange: ClosedRange<YearMonthDay>
    ) -> [YearMonthDay: DailyRecord] {
        // 1. 날짜별 그룹핑
        let groupedHK = Dictionary(grouping: healthKitWorkouts, by: \.yearMonthDay)
        let groupedRecords = Dictionary(grouping: savedRecords, by: \.yearMonthDay)

        // 2. 요청 범위의 모든 날짜 생성
        let allDates = generateDateRange(dateRange)

        // 3. 각 날짜별로 DailyRecord 생성
        var result: [YearMonthDay: DailyRecord] = [:]
        for date in allDates {
            let saved = groupedRecords[date] ?? []
            let healthKit = groupedHK[date] ?? []

            // 4. 중복 제거: SwiftData에 저장된 것은 HealthKit에서 제외
            let filteredHealthKit = healthKit.filter { workout in
                !saved.contains(where: { $0.startTime == workout.startDate })
            }

            result[date] = DailyRecord(
                yearMonthDay: date,
                healthKitWorkouts: filteredHealthKit.sorted { $0.startDate < $1.startDate },
                savedRecords: saved
            )
        }

        return result
    }

    /// 날짜 범위에 해당하는 모든 YearMonthDay 배열 생성
    private static func generateDateRange(_ range: ClosedRange<YearMonthDay>) -> [YearMonthDay] {
        var dates: [YearMonthDay] = []
        let calendar = Calendar.current

        var current = calendar.startOfDay(for: range.lowerBound.toDate())
        let end = calendar.startOfDay(for: range.upperBound.toDate())

        while current <= end {
            dates.append(YearMonthDay(date: current))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else {
                break
            }
            current = next
        }

        return dates
    }
}
