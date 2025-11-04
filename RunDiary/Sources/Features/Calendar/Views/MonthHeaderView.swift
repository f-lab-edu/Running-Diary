//
//  MonthHeaderView.swift
//  RunDiary
//
//  Created by 김혜지 on 11/4/25.
//

import CommonFoundation
import ComposableArchitecture
import HorizonCalendar
import SwiftUI

struct MonthHeaderView: View {
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
