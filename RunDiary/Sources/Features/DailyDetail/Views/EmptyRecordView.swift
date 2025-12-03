//
//  EmptyRecordView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI

struct EmptyRecordView: View {
    let error: DailyDetailError?

    init(error: DailyDetailError? = nil) {
        self.error = error
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                Image(systemName: iconName)
                    .font(.system(size: 60))
                    .foregroundColor(iconColor)

                Text(messageText)
                    .font(.headline)
                    .foregroundColor(.gray500)

                if let error = error, case .noHealthKitWorkout = error {
                    Text(error.recoverySuggestion ?? "")
                        .font(.caption)
                        .foregroundColor(.gray500)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(minHeight: 500)
    }

    private var iconName: String {
        if let error = error, case .noHealthKitWorkout = error {
            return "exclamationmark.triangle"
        }
        return "figure.run"
    }

    private var iconColor: Color {
        if let error = error, case .noHealthKitWorkout = error {
            return .orange
        }
        return .gray300
    }

    private var messageText: String {
        if let error = error {
            return error.errorDescription ?? L10n.Error.generic.value
        }
        return L10n.Record.empty.value
    }
}
