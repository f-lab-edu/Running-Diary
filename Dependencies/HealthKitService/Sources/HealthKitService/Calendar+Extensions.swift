//
//  Calendar+Extensions.swift
//  HealthKitService
//
//  Created by 김혜지 on 11/7/25.
//

import Foundation

extension Calendar {
    func endOfDay(for date: Date) -> Date? {
        let startOfDay = startOfDay(for: date)
        return self.date(byAdding: .day, value: 1, to: startOfDay) ?? nil
    }
}
