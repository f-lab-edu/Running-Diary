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
        VStack(spacing: 0) {
            TodayButton(
                isEnabled: store.state.isEnabledTodayButton,
                onTap: {
                    scrollToDay(.now, animated: true)
                    store.send(.selectDate(.today))
                }
            )

            CalendarContentView(
                store: store,
                proxy: proxy,
                onScroll: {
                    checkIfNeedsToLoadOlderData()
                    checkIfNeedsToSaveLastMonth()
                }
            )
            .padding(.horizontal, 4)

            DiarySwitchButton(
                selectedDate: store.selectedDate,
                onTap: {
                    store.send(.navigateToDiary)
                }
            )
        }
        .refreshable {
            await store.send(.refreshAll).finish()
        }
        .background(ignoresSafeAreaEdges: [.bottom])
        .onAppear {
            store.send(.onAppear)
            scrollToDay(store.selectedDate.toDate())
        }
        .animation(.linear(duration: 0.2), value: store.state.isEnabledTodayButton)
    }

    private func scrollToDay(_ date: Date, animated: Bool = false) {
        proxy.scrollToDay(
            containing: date,
            scrollPosition: .firstFullyVisiblePosition,
            animated: animated
        )
    }

    // 가장 오래된 달이 화면에 보일 때 과거 기록을 더 조회합니다.
    private func checkIfNeedsToLoadOlderData() {
        guard let oldestMonth = proxy.visibleMonthRange?.lowerBound else { return }
        let startDate = store.state.startDate
        guard startDate.year == oldestMonth.year && startDate.month == oldestMonth.month else { return }
        store.send(.oldestMonthBecameVisible)
    }

    // 오늘 날짜가 보이지 않을 때 자동 스크롤 버튼을 활성화시킬 수 있도록 보이는 달 중 최하단 달을 저장합니다.
    private func checkIfNeedsToSaveLastMonth() {
        guard let lastVisibleMonth = proxy.visibleMonthRange?.upperBound else { return }
        let yearMonth = YearMonth(year: lastVisibleMonth.year, month: lastVisibleMonth.month)
        store.send(.saveLastVisibleMonth(yearMonth))

    }
}

#Preview(traits: .sampleData) {
    CalendarView(
        store: Store(initialState: CalendarFeature.State(selectedDate: YearMonthDay(date: .now))) {
            CalendarFeature()
        } withDependencies: {
            $0.swiftDataClient = .previewValue
        }
    )
}
