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
            let isToday = isSameMonthToday(with: month)

            MonthHeaderView(
                month: month,
                totalDistance: totalDistance,
                isToday: isToday
            )
        }
        .days { day in
            let isToday = isSameDayToday(with: day)
            let date = calendar.date(from: day.components)
            let record = date.flatMap { date in
                let normalizedDate = calendar.startOfDay(for: date)
                return store.recordsByDate[normalizedDate] ?? nil
            }

            DayView(
                day: day,
                isToday: isToday,
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
                scrollPosition: .lastFullyVisiblePosition(padding: UIScreen.main.bounds.height * 0.35),
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

// MARK: - Private Views

private struct MonthHeaderView: View {
    let month: MonthComponents
    let totalDistance: Double
    let isToday: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Text("\(month.year.toString)년 \(month.month.toString)월")
                .font(.title2)
                .bold()
            if totalDistance > 0 {
                Text("총 \(String(format: "%.1f", totalDistance))km")
                    .bold()
                    .foregroundStyle(.gray)
            }
            Spacer()
        }
        .opacity(isToday ? 1 : 0.7)
        .padding([.horizontal, .bottom], 18)
    }
}

private struct DayView: View {
    let day: DayComponents
    let isToday: Bool
    let isSunday: Bool
    let record: RunningRecord?

    private var cellHeight: CGFloat {
        UIScreen.main.bounds.width / 7
    }

    var body: some View {
        ZStack {
            if isToday {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.blue.opacity(0.2))
            }

            VStack {
                Text(String(day.day))
                    .foregroundStyle(isSunday ? .red : .black)
                    .opacity(isToday ? 1 : 0.7)
                    .bold()
                Spacer()
                Text(record.map { "\($0.distanceInKilometers.to1f)km" } ?? "-")
                    .font(.caption)
                    .foregroundStyle(isToday ? .black : .gray)
                    .opacity(record != nil ? 1 : 0.2)
            }
            .padding(10)
        }
        .frame(minHeight: cellHeight)
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
