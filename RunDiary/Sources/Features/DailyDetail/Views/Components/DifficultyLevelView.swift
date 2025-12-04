//
//  DifficultyLevelView.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import SwiftUI

struct DifficultyLevelView: View {
    let difficultyLevel: Int?

    init(difficultyLevel: Int?) {
        self.difficultyLevel = difficultyLevel
    }

    var body: some View {
        if let difficultyLevel = difficultyLevel {
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= difficultyLevel ? "star.fill" : "star")
                        .foregroundColor(index <= difficultyLevel ? .yellow : .gray.opacity(0.3))
                        .font(.system(size: 20))
                }
            }
        }
    }
}
