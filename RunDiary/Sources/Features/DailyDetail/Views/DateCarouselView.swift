//
//  DateCarouselView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CommonFoundation
import ComposableArchitecture
import SwiftUI

struct DateCarouselView: View {
    let store: StoreOf<DailyDetailFeature>

    @State private var dragOffset: CGFloat = 0
    @State private var currentOffset: CGFloat = 0
    
    init(store: StoreOf<DailyDetailFeature>) {
        self.store = store
    }
    
    var body: some View {
        GeometryReader { _ in
            HStack(spacing: 0) {
                // 이전 주
                WeekView(
                    store: store,
                    dates: DateHelper.getWeekDates(
                        for: DateHelper.addWeeks(-1, to: store.currentWeekDates.first ?? Date())
                    ),
                    selectedDate: Binding(
                        get: { store.selectedDate },
                        set: { store.send(.dateSelected($0)) }
                    )
                )
                .frame(width: screenWidth)
                
                // 현재 주
                WeekView(
                    store: store,
                    dates: store.currentWeekDates,
                    selectedDate: Binding(
                        get: { store.selectedDate },
                        set: { store.send(.dateSelected($0)) }
                    )
                )
                .frame(width: screenWidth)
                
                // 다음 주
                WeekView(
                    store: store,
                    dates: DateHelper.getWeekDates(
                        for: DateHelper.addWeeks(1, to: store.currentWeekDates.first ?? Date())
                    ),
                    selectedDate: Binding(
                        get: { store.selectedDate },
                        set: { store.send(.dateSelected($0)) }
                    )
                )
                .frame(width: screenWidth)
            }
            .offset(x: -screenWidth + dragOffset + currentOffset)
            .gesture(
                DragGesture()
                    .onChanged { handleDragChanged($0) }
                    .onEnded { handleDragEnded($0) }
            )
        }
        .frame(height: 80)
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        dragOffset = value.translation.width
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        let threshold = screenWidth * 0.3
        let swipeDistance = value.translation.width

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if swipeDistance > threshold {
                // 오른쪽 스와이프 → 이전 주
                currentOffset = screenWidth
            } else if swipeDistance < -threshold {
                // 왼쪽 스와이프 → 다음 주
                currentOffset = -screenWidth
            }
            dragOffset = 0
        }

        if abs(swipeDistance) > threshold {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if swipeDistance > threshold {
                    store.send(.weekChanged(offset: -1))
                } else {
                    store.send(.weekChanged(offset: 1))
                }
                currentOffset = 0
            }
        }
    }
}

private struct WeekView: View {
    let store: StoreOf<DailyDetailFeature>
    let dates: [Date]
    @Binding var selectedDate: Date

    init(
        store: StoreOf<DailyDetailFeature>,
        dates: [Date],
        selectedDate: Binding<Date>,
    ) {
        self.store = store
        self.dates = dates
        self._selectedDate = selectedDate
    }
    
    private let horizontalPadding: CGFloat = 14
    private let itemSpacing: CGFloat = 10
    private let numberOfItems: CGFloat = 7
    
    var body: some View {
        GeometryReader { _ in
            let totalPadding = horizontalPadding * 2
            let totalSpacing = itemSpacing * (numberOfItems - 1)
            let availableWidth = screenWidth - totalPadding - totalSpacing
            let itemWidth = availableWidth / numberOfItems
            
            HStack(spacing: itemSpacing) {
                ForEach(dates, id: \.self) { date in
                    Button {
                        selectedDate = date
                    } label: {
                        DateItemView(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            hasRecord: hasRecord(on: date),
                            width: itemWidth
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
    }

    private func hasRecord(on date: Date) -> Bool {
        guard let value = store.cachedRecords[date] else { return false }
        return value != nil
    }
}

private struct DateItemView: View {
    let date: Date
    let isSelected: Bool
    let hasRecord: Bool
    let width: CGFloat
    
    init(
        date: Date,
        isSelected: Bool,
        hasRecord: Bool,
        width: CGFloat = 50
    ) {
        self.date = date
        self.isSelected = isSelected
        self.hasRecord = hasRecord
        self.width = width
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    private var day: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(dayOfWeek)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .gray700)
            
            Text(day)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .gray700)

            // 후보 1
            Circle()
                .frame(width: 6, height: 6)
                .foregroundStyle(hasRecord ? .yellow100 : .clear)
                .padding(.top, 2)
        }
        .frame(width: width)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(isSelected ? Color.blue700 : Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.clear : Color.gray100, lineWidth: 1)
        )
        .fixedSize(horizontal: false, vertical: true)
    }
}
