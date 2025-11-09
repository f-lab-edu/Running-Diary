//
//  EmptyRecordView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI

struct EmptyRecordView: View {
    let error: DailyDetailError?
    let onAddRecord: () -> Void

    init(error: DailyDetailError? = nil, onAddRecord: @escaping () -> Void) {
        self.error = error
        self.onAddRecord = onAddRecord
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

                if let error = error, case .noHealthKitData = error {
                    Text(error.recoverySuggestion ?? "")
                        .font(.caption)
                        .foregroundColor(.gray500)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                } else {
                    Button(action: onAddRecord) {
                        ZStack {
                            Capsule()
                                .foregroundStyle(.yellow100)

                            Text("기록을 추가해주세요!")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue700)
                                .padding()
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 40)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(minHeight: 500)
    }

    private var iconName: String {
        if let error = error, case .noHealthKitData = error {
            return "exclamationmark.triangle"
        }
        return "figure.run"
    }

    private var iconColor: Color {
        if let error = error, case .noHealthKitData = error {
            return .orange
        }
        return .gray300
    }

    private var messageText: String {
        if let error = error {
            return error.errorDescription ?? "오류가 발생했습니다"
        }
        return "러닝 기록이 없습니다"
    }
}
