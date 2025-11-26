//
//  DayView.swift
//  RunDiary
//
//  Created by 김혜지 on 11/4/25.
//

import CommonFoundation
import ComposableArchitecture
import Models
import SwiftUI

struct DayView: View {
    let day: Int
    let isSunday: Bool
    let isToday: Bool
    let records: [RunningRecord]
    let isSelected: Bool

    private var cellHeight: CGFloat {
        screenWidth / 7
    }
    private var totalDistance: Double? {
        guard !records.isEmpty else { return nil }
        return records.reduce(0) { $0 + $1.distanceInKilometers }
    }

    init(
        day: Int,
        isSunday: Bool,
        isToday: Bool,
        records: [RunningRecord],
        isSelected: Bool
    ) {
        self.day = day
        self.isSunday = isSunday
        self.isToday = isToday
        self.records = records
        self.isSelected = isSelected
    }

    var body: some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.blue300)
                    .padding(2)
            }

            VStack {
                Text(String(day))
                    .foregroundStyle(isSelected ? .white : (isSunday ? .red : isToday ? .blue300 : .black))
                    .opacity(isSelected || isToday ? 1 : 0.7)
                    .bold(isSelected || isToday)
                Spacer()
                Text(totalDistance.map { "\($0.to1f)km" } ?? "-")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .gray)
                    .opacity(records.isEmpty ? 0.2 : 1)
                    .bold(!totalDistance.isNil && isToday)
            }
            .padding(10)
        }
        .frame(minHeight: cellHeight)
    }
}
