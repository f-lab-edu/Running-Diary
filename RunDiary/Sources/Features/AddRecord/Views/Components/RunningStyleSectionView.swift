//
//  RunningStyleSectionView.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import Models
import SwiftUI

struct RunningStyleSectionView: View {
    @Binding var selectedStyle: RunninStyle?
    let styleOptions: [RunninStyle]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.Record.Field.runningStyle.text
                .font(.headline)
                .padding(.bottom, 4)

            Menu {
                ForEach(styleOptions, id: \.self) { style in
                    Button(style.localizedName) {
                        selectedStyle = style
                    }
                }
            } label: {
                HStack {
                    Text(selectedStyle?.localizedName ?? L10n.Record.Field.runningStylePlaceholder.value)
                        .foregroundColor(selectedStyle == nil ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
