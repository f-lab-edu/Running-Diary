//
//  DateCarouselView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

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
    GeometryReader { geometry in
      let screenWidth = geometry.size.width

      HStack(spacing: 0) {
        // 이전 주
        WeekView(
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
          dates: store.currentWeekDates,
          selectedDate: Binding(
            get: { store.selectedDate },
            set: { store.send(.dateSelected($0)) }
          )
        )
        .frame(width: screenWidth)

        // 다음 주
        WeekView(
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
          .onChanged { value in
            dragOffset = value.translation.width
          }
          .onEnded { value in
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
      )
    }
    .frame(height: 80)
  }
}

private struct WeekView: View {
  let dates: [Date]
  @Binding var selectedDate: Date

  init(dates: [Date], selectedDate: Binding<Date>) {
    self.dates = dates
    self._selectedDate = selectedDate
  }

  private let horizontalPadding: CGFloat = 14
  private let itemSpacing: CGFloat = 10
  private let numberOfItems: CGFloat = 7

  var body: some View {
    GeometryReader { geometry in
      let totalPadding = horizontalPadding * 2
      let totalSpacing = itemSpacing * (numberOfItems - 1)
      let availableWidth = UIScreen.main.bounds.width - totalPadding - totalSpacing
      let itemWidth = availableWidth / numberOfItems

      HStack(spacing: itemSpacing) {
        ForEach(dates, id: \.self) { date in
          DateItemView(
            date: date,
            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
            width: itemWidth
          )
          .onTapGesture {
            selectedDate = date
          }
        }
      }
      .padding(.horizontal, horizontalPadding)
    }
  }
}

private struct DateItemView: View {
  let date: Date
  let isSelected: Bool
  let width: CGFloat

  init(date: Date, isSelected: Bool, width: CGFloat = 50) {
    self.date = date
    self.isSelected = isSelected
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
    VStack(spacing: 4) {
      Text(dayOfWeek)
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(isSelected ? .white : .gray)

      Text(day)
        .font(.headline)
        .foregroundColor(isSelected ? .white : .black)
    }
    .frame(width: width, height: 60)
    .background(isSelected ? Color.blue : Color.clear)
    .cornerRadius(10)
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
    )
  }
}
