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

    init(store: StoreOf<CalendarFeature>) {
        self.store = store
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            CalendarViewRepresentable(
                calendar: .current,
                visibleDateRange: store.startDate.toDate()...store.endDate.toDate(),
                monthsLayout: .vertical(options: VerticalMonthsLayoutOptions(pinDaysOfWeekToTop: true)),
                dataDependency: (store.recordsByDate, store.selectedDate),
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
                    record: store.recordsByDate[$0.yearMonthDay, default: nil],
                    isSelected: store.selectedDate == $0.yearMonthDay
                )
            }
            .onDaySelection {
                store.send(.selectDate($0.yearMonthDay))
                scrollToDay(store.state.selectedDate.toDate(), animated: true)
            }
            .onScroll { _, _ in
                checkIfNeedsToLoadOlderData()
                checkIfNeedsToSaveLastDate()
            }

            if store.state.canAutoScrollToToday {
                Button {
                    scrollToDay(.now, animated: true)
                } label: {
                    Image(systemName: "arrow.down.to.line")
                        .resizable()
                        .scaledToFit()
                        .square(screenWidth * 0.06)
                        .foregroundStyle(.blue700)
                        .padding(12)
                        .background(
                            Circle()
                                .foregroundStyle(.yellow100)
                        )
                }
                .padding(24)
                .transition(.opacity)
            }
        }
        .onAppear {
            store.send(.onAppear)
            scrollToDay(.now)
        }
        .animation(.linear, value: store.state.canAutoScrollToToday)
    }

    private func scrollToDay(_ date: Date, animated: Bool = false) {
        proxy.scrollToDay(
            containing: date,
            scrollPosition: .lastFullyVisiblePosition(padding: screenHeight * 0.35),
            animated: animated
        )
    }

    // 가장 오래된 달이 화면에 보일 때 과거 기록을 더 조회합니다.
    private func checkIfNeedsToLoadOlderData() {
        guard let oldestMonth = proxy.visibleMonthRange?.lowerBound else { return }
        let startDate = store.state.startDate
        guard startDate.year == oldestMonth.year, startDate.month == oldestMonth.month else { return }
        store.send(.oldestMonthBecameVisible)
    }

    private func checkIfNeedsToSaveLastDate() {
        guard let lastVisibleMonth = proxy.visibleMonthRange?.upperBound else { return }
        let yearMonth = YearMonth(year: lastVisibleMonth.year, month: lastVisibleMonth.month)
        store.send(.saveLastVisibleMonth(yearMonth))

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
