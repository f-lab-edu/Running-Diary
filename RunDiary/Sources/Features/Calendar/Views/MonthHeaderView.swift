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
            Text("\(year.toString)년 \(month.toString)월")
                .font(.title2)
                .bold()
            if totalDistance > 0 {
                Text("총 \(totalDistance.to1f)km")
                    .bold()
                    .foregroundStyle(.gray)
            }
            Spacer()
        }
        .padding([.horizontal, .bottom], 18)
    }
}
