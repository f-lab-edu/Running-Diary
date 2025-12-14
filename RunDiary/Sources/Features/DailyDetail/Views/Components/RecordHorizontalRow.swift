//
//  RecordHorizontalRow.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import SwiftUI

struct RecordHorizontalRow: View {
    let title: String
    let value: String

    init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray500)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(.gray700)
        }
    }
}
