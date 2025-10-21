//
//  DateHelper.swift
//  RunDiary
//
//  Created by 김혜지 on 10/21/25.
//

import Foundation

enum DateHelper {
    static func generateSurroundingDates(
        from date: Date,
        range: Int = 14,
        calendar: Calendar = .current
    ) -> [Date] {
        let today = calendar.startOfDay(for: date)
        return (-range...range).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }
}
