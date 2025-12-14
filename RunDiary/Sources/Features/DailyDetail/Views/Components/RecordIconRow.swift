//
//  RecordIconRow.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import SwiftUI

struct RecordIconRow: View {
    let title: String
    let isChecked: Bool

    init(title: String, isChecked: Bool) {
        self.title = title
        self.isChecked = isChecked
    }

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)

            Spacer()

            Image(systemName: isChecked ? "checkmark.app.fill" : "xmark.app.fill")
                .foregroundColor(isChecked ? .blue700 : .gray300)
                .font(.title3)
        }
    }
}
