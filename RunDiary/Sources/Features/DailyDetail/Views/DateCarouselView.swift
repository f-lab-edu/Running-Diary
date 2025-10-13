//
//  DateCarouselView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI

struct DateCarouselView: View {
    let dates: [Date]
    @Binding var selectedDate: Date

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dates, id: \.self) { date in
                        DateItemView(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                        .id(date)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onAppear {
                proxy.scrollTo(selectedDate, anchor: .center)
            }
            .onChange(of: selectedDate) { _, newDate in
                withAnimation {
                    proxy.scrollTo(newDate, anchor: .center)
                }
            }
        }
    }
}

struct DateItemView: View {
    let date: Date
    let isSelected: Bool

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    private var monthAndDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    private var dayOfWeekColor: Color {
        switch dayOfWeek {
        case "토":
            return .blue
        case "일":
            return .red
        default:
            return .gray
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayOfWeek)
                .font(.caption)
                .foregroundColor(dayOfWeekColor)

            Text(monthAndDay)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(width: 50, height: 60)
        .background(Color.clear)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
    }
}
