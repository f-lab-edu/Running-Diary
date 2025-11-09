//
//  DiarySwitchButton.swift
//  RunDiary
//
//  Created by 김혜지 on 11/9/25.
//

import Models
import SwiftUI

struct DiarySwitchButton: View {
    let selectedDate: YearMonthDay
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Capsule()
                    .foregroundStyle(.yellow100)

                Text("\(selectedDate.month)월 \(selectedDate.day)일 다이어리 보기")
                    .bold()
                    .foregroundStyle(.blue700)
                    .padding(.vertical, 12)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
    }
}

#Preview {
    DiarySwitchButton(
        selectedDate: YearMonthDay(year: 2025, month: 11, day: 9),
        onTap: {}
    )
}
