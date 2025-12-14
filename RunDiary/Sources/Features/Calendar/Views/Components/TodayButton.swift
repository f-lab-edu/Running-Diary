//
//  TodayButton.swift
//  RunDiary
//
//  Created by 김혜지 on 11/9/25.
//

import CommonFoundation
import SwiftUI

struct TodayButton: View {
    let isEnabled: Bool
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

                    L10n.uiToday.text
                        .font(.footnote)
                        .bold()
                }
                .padding(6)
                .background(
                    Capsule()
                        .stroke(lineWidth: 1)
                )
                .foregroundStyle(isEnabled ? .blue300 : .gray300)
            }
            .disabled(!isEnabled)
            .padding([.top, .trailing], 24)
            .padding(.bottom, 4)
            .transition(.opacity)
        }
    }
}

#Preview {
    VStack {
        TodayButton(isEnabled: true, onTap: {})
        TodayButton(isEnabled: false, onTap: {})
    }
}
