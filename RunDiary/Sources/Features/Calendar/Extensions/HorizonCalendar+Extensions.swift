//
//  HorizonCalendar+Extensions.swift
//  RunDiary
//
//  Created by 김혜지 on 11/7/25.
//

import Foundation
import HorizonCalendar
import Models

extension DayComponents {
    var yearMonthDay: YearMonthDay {
        YearMonthDay(year: month.year, month: month.month, day: day)
    }

    var isSunday: Bool {
        guard let date = components.date else { return false }
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1
    }
}
