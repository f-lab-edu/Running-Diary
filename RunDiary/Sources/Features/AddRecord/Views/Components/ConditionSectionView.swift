//
//  ConditionSectionView.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import SwiftUI

struct ConditionSectionView: View {
    @Binding var sleepHours: String
    @Binding var hadMeal: Bool
    @Binding var hadAlcohol: Bool
    @Binding var memo: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.Record.Field.condition.text
                .font(.headline)
                .padding(.bottom, 4)

            VStack(spacing: 12) {
                HStack {
                    L10n.Record.Field.sleepDuration.text
                        .foregroundColor(.gray)
                    Spacer()
                    TextField("8", text: $sleepHours)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: sleepHours) { oldValue, newValue in
                            // 빈 값 허용 (입력 전/전체 삭제)
                            if newValue.isEmpty {
                                return
                            }

                            // 정수 변환 및 범위 검증
                            if let value = Int(newValue) {
                                if value < 1 {
                                    // 1 미만 → 1로 자동 보정
                                    sleepHours = "1"
                                } else if value > 24 {
                                    // 24 초과 → 24로 자동 보정
                                    sleepHours = "24"
                                }
                                // 1~24 범위는 그대로 유지
                            } else {
                                // 숫자가 아닌 경우 → 이전 값으로 되돌림
                                sleepHours = oldValue
                            }
                        }
                    L10n.Unit.hours.text
                        .foregroundColor(.gray)
                }

                HStack {
                    L10n.Record.Field.hasMeal.text
                        .foregroundColor(.gray)
                    Spacer()
                    CheckboxView(isChecked: $hadMeal)
                }

                HStack {
                    L10n.Record.Field.wasDrinking.text
                        .foregroundColor(.gray)
                    Spacer()
                    CheckboxView(isChecked: $hadAlcohol)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct CheckboxView: View {
    @Binding var isChecked: Bool

    var body: some View {
        Button(action: {
            isChecked.toggle()
        }) {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .foregroundColor(isChecked ? .blue : .gray)
                .font(.title2)
        }
        .buttonStyle(.plain)
    }
}
