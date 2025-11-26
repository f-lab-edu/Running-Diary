//
//  DifficultyLevel+Localization.swift
//  RunDiary
//
//  Created by Claude on 11/26/25.
//

import Foundation
import Models

extension DifficultyLevel {
    var displayName: String {
        switch self {
        case .veryEasy:
            return String(localized: "difficulty_level.very_easy")
        case .easy:
            return String(localized: "difficulty_level.easy")
        case .medium:
            return String(localized: "difficulty_level.medium")
        case .hard:
            return String(localized: "difficulty_level.hard")
        case .veryHard:
            return String(localized: "difficulty_level.very_hard")
        }
    }
}
