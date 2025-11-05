//
//  DayView.swift
//  RunDiary
//
//  Created by 김혜지 on 11/4/25.
//

import CommonFoundation
import ComposableArchitecture
import HorizonCalendar
import Models
import SwiftUI

struct DayView: View {
    let day: DayComponents
    let isToday: Bool
    let isSunday: Bool
    let record: RunningRecord?

    private var cellHeight: CGFloat {
        screenWidth / 7
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
