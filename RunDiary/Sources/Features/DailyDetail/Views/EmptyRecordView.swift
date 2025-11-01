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
          .foregroundColor(.gray)

        Text("러닝 기록이 없습니다")
          .font(.headline)
          .foregroundColor(.gray)

        Button(action: onAddRecord) {
          Text("기록 추가하기")
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding(.horizontal, 40)
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .frame(minHeight: 500)
  }
}
