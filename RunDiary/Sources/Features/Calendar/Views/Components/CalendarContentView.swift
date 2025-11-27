//
//  CalendarContentView.swift
//  RunDiary
//
//  Created by 김혜지 on 11/9/25.
//

import ComposableArchitecture
import HorizonCalendar
import Models
import SwiftUI

struct CalendarContentView: View {
    @Bindable var store: StoreOf<CalendarFeature>
    let proxy: CalendarViewProxy
    let onScroll: () -> Void

    var body: some View {
        CalendarViewRepresentable(
            calendar: .current,
            visibleDateRange: store.startDate.toDate()...store.endDate.toDate(),
            monthsLayout: .vertical(options: VerticalMonthsLayoutOptions(pinDaysOfWeekToTop: true)),
            dataDependency: (store.runningRecords, store.selectedDate),
            proxy: proxy
        )
        .interMonthSpacing(40)
        .daysOfTheWeekRowSeparator(options: .systemStyleSeparator)
        .monthHeaders {
            MonthHeaderView(
                year: $0.year,
                month: $0.month,
                totalDistance: store.monthlyTotals[YearMonth(year: $0.year, month: $0.month), default: 0]
            )
        }
        .days {
            DayView(
                day: $0.day,
                isSunday: $0.isSunday,
                isToday: $0.yearMonthDay == YearMonthDay.today,
                records: store.runningRecords[$0.yearMonthDay, default: []],
                isSelected: store.selectedDate == $0.yearMonthDay,
                hasUnsavedWorkout: store.dailyRecords[$0.yearMonthDay]?.hasHealthKitData ?? false
            )
        }
        .onDaySelection {
            store.send(.selectDate($0.yearMonthDay))
        }
        .onScroll { _, _ in
            onScroll()
        }
    }
}
