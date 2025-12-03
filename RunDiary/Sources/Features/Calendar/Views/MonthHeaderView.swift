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
            Text(DateHelper.formattedYearMonth(year: year, month: month))
                .font(.title2)
                .bold()
            if totalDistance > 0 {
                L10n.Format.totalKm.text(totalDistance.to1f)
                    .bold()
                    .foregroundStyle(.gray)
            }
            Spacer()
        }
        .padding([.horizontal, .bottom], 18)
    }
}
