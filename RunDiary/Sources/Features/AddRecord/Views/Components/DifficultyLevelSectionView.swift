//
//  DifficultyLevelSectionView.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import Models
import SwiftUI

struct DifficultyLevelSectionView: View {
    @Binding var selectedLevel: DifficultyLevel?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.Record.Field.intensity.text
                .font(.headline)
                .padding(.bottom, 4)

            Menu {
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    Button(level.displayName) {
                        selectedLevel = level
                    }
                }
            } label: {
                HStack {
                    Text(selectedLevel?.displayName ?? L10n.Record.Field.intensityPlaceholder.value)
                        .foregroundColor(selectedLevel == nil ? .gray : .primary)
                    Spacer()
                    if let level = selectedLevel {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= level.rawValue ? "star.fill" : "star")
                                    .foregroundColor(index <= level.rawValue ? .yellow : .gray)
                                    .font(.caption)
                            }
                        }
                    }
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
