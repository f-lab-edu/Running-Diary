//
//  MonthHeaderView.swift
//  RunDiary
//
//  Created by 김혜지 on 11/4/25.
//

import CommonFoundation
import ComposableArchitecture
import SwiftUI

struct MonthHeaderView: View {
    let year: Int
    let month: Int
    let totalDistance: Double

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Text(String.localizedStringWithFormat(
                String(localized: "%@년 %@월"),
                year.toString,
                month.toString
            ))
                .font(.title2)
                .bold()
            if totalDistance > 0 {
                Text(String.localizedStringWithFormat(
                    String(localized: "총 %@km"),
                    totalDistance.to1f
                ))
                    .bold()
                    .foregroundStyle(.gray)
            }
            Spacer()
        }
        .padding([.horizontal, .bottom], 18)
    }
}
