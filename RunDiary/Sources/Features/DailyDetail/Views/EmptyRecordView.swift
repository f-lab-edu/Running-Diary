//
//  EmptyRecordView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI

struct EmptyRecordView: View {
    let onAddRecord: () -> Void

    init(onAddRecord: @escaping () -> Void) {
        self.onAddRecord = onAddRecord
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                Image(systemName: "figure.run")
                    .font(.system(size: 60))
                    .foregroundColor(.gray300)

                Text("러닝 기록이 없습니다")
                    .font(.headline)
                    .foregroundColor(.gray500)

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
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(minHeight: 500)
    }
}
