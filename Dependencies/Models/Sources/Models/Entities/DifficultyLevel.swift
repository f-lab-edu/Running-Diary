//
//  DifficultyLevel.swift
//  Models
//
//  Created by 김혜지 on 10/31/25.
//

public enum DifficultyLevel: Int, CaseIterable, Sendable, Equatable {
    case veryEasy = 1
    case easy
    case medium
    case hard
    case veryHard
    
    public var displayName: String {
        switch self {
        case .veryEasy:
            return "매우 쉬움"
        case .easy:
            return "쉬움"
        case .medium:
            return "보통"
        case .hard:
            return "어려움"
        case .veryHard:
            return "매우 어려움"
        }
    }
}
