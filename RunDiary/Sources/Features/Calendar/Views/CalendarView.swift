//
//  CalendarView.swift
//  RunDiary
//
//  Created by 김혜지 on 11/3/25.
//

import CommonFoundation
import ComposableArchitecture
import HorizonCalendar
import Models
import SwiftUI

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var proxy = CalendarViewProxy()

    @Bindable var store: StoreOf<CalendarFeature>

    let calendar: Calendar
    let today: Date
    let todayComponents: DateComponents

    init(store: StoreOf<CalendarFeature>) {
        self.store = store
        self.calendar = Calendar.current
        self.today = Date()
        self.todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
    }

    var body: some View {
        CalendarViewRepresentable(
            calendar: calendar,
            visibleDateRange: store.startDate...store.endDate,
            monthsLayout: .vertical(options: VerticalMonthsLayoutOptions(pinDaysOfWeekToTop: true)),
            dataDependency: store.recordsByDate,
            proxy: proxy
        )
        .daysOfTheWeekRowSeparator(options: .systemStyleSeparator)
        .interMonthSpacing(40)
        .monthHeaders { month in
            let yearMonth = String(format: "%04d-%02d", month.year, month.month)
            let totalDistance = store.monthlyTotals[yearMonth] ?? 0.0

            MonthHeaderView(
                month: month,
                totalDistance: totalDistance,
                isToday: isSameMonthToday(with: month)
            )
        }
        .days { day in
            let date = calendar.date(from: day.components)
            let record = date.flatMap { date in
                let normalizedDate = calendar.startOfDay(for: date)
                return store.recordsByDate[normalizedDate] ?? nil
            }

            DayView(
                day: day,
                isToday: isSameDayToday(with: day),
                isSunday: isSunday(currentDay: day),
                record: record
            )
        }
        .onScroll { _, isUserDragging in
            // HorizonCalendar API를 사용하여 가장 오래된 달이 화면에 보이는 때를 감지합니다.
            guard isUserDragging, let firstVisibleMonth = proxy.visibleMonthRange?.lowerBound else { return }
            let oldestDateComponents = store.state.startDateComponents
            guard oldestDateComponents.year == firstVisibleMonth.year, oldestDateComponents.month == firstVisibleMonth.month else { return }
            store.send(.oldestMonthBecameVisible)
        }
        .onAppear {
            store.send(.onAppear)
            proxy.scrollToDay(
                containing: today,
                scrollPosition: .lastFullyVisiblePosition(padding: screenHeight * 0.35),
                animated: false
            )
        }
    }

    private func isSameDayToday(with day: DayComponents) -> Bool {
        guard let tYear = todayComponents.year, let tMonth = todayComponents.month, let tDay = todayComponents.day else { return false }
        let isSameDay = day.day == tDay
        let isSameMonth = day.month.month == tMonth
        let isSameYear = day.month.year == tYear
        return isSameYear && isSameMonth && isSameDay
    }

    private func isSameMonthToday(with month: MonthComponents) -> Bool {
        guard let tYear = todayComponents.year, let tMonth = todayComponents.month else { return false }
        let isSameMonth = month.month == tMonth
        let isSameYear = month.year == tYear
        return isSameYear && isSameMonth
    }

    private func isSunday(currentDay: DayComponents) -> Bool {
        guard let date = calendar.date(from: currentDay.components) else { return false }
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1
    }
}

#Preview(traits: .sampleData) {
    CalendarView(
        store: Store(initialState: CalendarFeature.State()) {
            CalendarFeature()
        } withDependencies: {
            $0.repositoryClient = .previewValue
        }
    )
}
