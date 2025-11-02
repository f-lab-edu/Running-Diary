//
//  CalendarView.swift
//  RunDiary
//
//  Created by 김혜지 on 11/3/25.
//

import CommonFoundation
import HorizonCalendar
import SwiftUI

struct CalendarView: View {
    let calendar: Calendar
    let today: Date
    let todayComponents: DateComponents
    let startDate: Date
    let endDate: Date

    @StateObject private var proxy = CalendarViewProxy()

    init() {
        self.calendar = Calendar.current
        self.today = Date()
        self.todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        self.startDate = calendar.date(byAdding: .year, value: -1, to: today)!
        self.endDate = calendar.date(byAdding: .month, value: 1, to: today)!
    }

    var body: some View {
        CalendarViewRepresentable(
            calendar: calendar,
            visibleDateRange: startDate...endDate,
            monthsLayout: .vertical(options: VerticalMonthsLayoutOptions(pinDaysOfWeekToTop: true)),
            dataDependency: nil,
            proxy: proxy
        )
        .monthHeaders { month in
            HStack(alignment: .bottom, spacing: 10) {
                Text("\(month.year.toString)년 \(month.month.toString)월")
                    .font(.title2)
                    .bold()
                Text("총 10km")
                    .bold()
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding(.bottom, 16)
        }
        .days { day in
            let isToday = isSameDayToday(with: day)
            
            ZStack {
                if isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.blue.opacity(0.2))
                }

                VStack {
                    Text(String(day.day))
                        .foregroundStyle(isSunday(currentDay: day) ? .red : .black)
                        .bold()
                    Spacer()
                    Text("3.2km")
                        .font(.caption)
                        .foregroundStyle(isToday ? .black : .gray)
                }
                .padding(10)
            }
            .fixedSize()
        }
        .interMonthSpacing(40)
        .onAppear {
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

    private func isSunday(currentDay: DayComponents) -> Bool {
        guard let date = calendar.date(from: currentDay.components) else { return false }
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1
    }
}

#Preview {
    CalendarView()
}
