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
    let record: RunningRecord?
    var isSelected: Bool

    private var cellHeight: CGFloat {
        screenWidth / 7
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
                    .foregroundStyle(isSelected ? .white : (isSunday ? .red : .black))
                    .opacity(isSelected ? 1 : 0.7)
                    .bold(isSelected)
                Spacer()
                Text(record.map { "\($0.distanceInKilometers.to1f)km" } ?? "-")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .gray)
                    .opacity(record != nil ? 1 : 0.2)
            }
            .padding(10)
        }
        .frame(minHeight: cellHeight)
    }
}
