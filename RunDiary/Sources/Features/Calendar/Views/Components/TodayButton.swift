//
//  TodayButton.swift
//  RunDiary
//
//  Created by 김혜지 on 11/9/25.
//

import CommonFoundation
import SwiftUI

struct TodayButton: View {
    let canAutoScrollToToday: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            Button(action: onTap) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.clockwise")
                        .resizable()
                        .scaledToFit()
                        .square(screenWidth * 0.03)

                    Text("오늘")
                        .font(.footnote)
                        .bold()
                }
                .padding(6)
                .background(
                    Capsule()
                        .stroke(lineWidth: 1)
                )
                .foregroundStyle(canAutoScrollToToday ? .blue300 : .gray300)
            }
            .disabled(!canAutoScrollToToday)
            .padding([.top, .trailing], 24)
            .padding(.bottom, 4)
            .transition(.opacity)
        }
    }
}

#Preview {
    VStack {
        TodayButton(canAutoScrollToToday: true, onTap: {})
        TodayButton(canAutoScrollToToday: false, onTap: {})
    }
}
