//
//  YearMonthDay.swift
//  Models
//
//  Created by 김혜지 on 11/7/25.
//

import Foundation

public struct YearMonthDay: Comparable, Equatable, Hashable, Sendable {
    public static let today = YearMonthDay(date: .now)

    public let year: Int
    public let month: Int
    public let day: Int

    public var full: String {
        "\(year)년 \(month)월 \(day)일"
    }

    public var compact: String {
        "\(month)월 \(day)일"
    }

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(date: Date) {
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        self.year = dateComponents.year!
        self.month = dateComponents.month!
        self.day = dateComponents.day!
    }

    public func toDate() -> Date {
        let dateComponents = DateComponents(year: year, month: month, day: day)
        return Calendar.current.date(from: dateComponents)!
    }

    public func toYearMonth() -> YearMonth {
        YearMonth(year: year, month: month)
    }

    public func add(day: Int) -> YearMonthDay? {
        guard let date = Calendar.current.date(byAdding: .day, value: day, to: toDate()) else { return nil }
        return YearMonthDay(date: date)
    }

    public func add(week: Int) -> YearMonthDay? {
        guard let date = Calendar.current.date(byAdding: .weekOfYear, value: week, to: toDate()) else { return nil }
        return YearMonthDay(date: date)
    }

    public func add(month: Int) -> YearMonthDay? {
        guard let date = Calendar.current.date(byAdding: .month, value: month, to: toDate()) else { return nil }
        return YearMonthDay(date: date)
    }

    public static func < (lhs: YearMonthDay, rhs: YearMonthDay) -> Bool {
        guard lhs.year == rhs.year else { return lhs.year < rhs.year }
        guard lhs.month == rhs.month else { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }
}

public struct YearMonth: Comparable, Equatable, Hashable {
    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    public init(date: Date) {
        let dateComponents = Calendar.current.dateComponents([.year, .month], from: date)
        self.year = dateComponents.year!
        self.month = dateComponents.month!
    }

    public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        guard lhs.year == rhs.year else { return lhs.year < rhs.year }
        return lhs.month < rhs.month
    }
}

extension Date {
    public var toYearMonthDay: YearMonthDay {
        YearMonthDay(date: self)
    }

    public var toYearMonth: YearMonth {
        YearMonth(date: self)
    }
}
