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

    /// 특정 날짜가 속한 주의 월요일 반환
    static func startOfWeek(
        for date: Date,
        calendar: Calendar = .current
    ) -> Date {
        var modifiedCalendar = calendar
        modifiedCalendar.firstWeekday = 2 // 월요일 시작

        let components = modifiedCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return modifiedCalendar.date(from: components) ?? date
    }

    /// 특정 날짜가 속한 주의 월~일 7일 반환
    static func getWeekDates(
        for date: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        let startOfWeek = startOfWeek(for: date, calendar: calendar)
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }

    /// 특정 날짜에서 N주 이동
    static func addWeeks(
        _ weeks: Int,
        to date: Date,
        calendar: Calendar = .current
    ) -> Date {
        calendar.date(byAdding: .weekOfYear, value: weeks, to: date) ?? date
    }
}
