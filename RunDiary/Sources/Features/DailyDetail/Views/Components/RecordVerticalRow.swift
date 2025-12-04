//
//  RecordVerticalRow.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import SwiftUI

struct RecordVerticalRow: View {
    let title: String
    let value: String

    init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray500)

                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue700)
            }
            .padding(.leading, 4)
            Spacer()
        }
    }
}
