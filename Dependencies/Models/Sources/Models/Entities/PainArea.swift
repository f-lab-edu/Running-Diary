//
//  PainArea.swift
//  RunDiary
//
//  Created by Claude on 10/22/25.
//

import Foundation

/// 러닝 중 발생할 수 있는 통증 부위
public enum PainArea: String, CaseIterable, Sendable, Equatable {
    case knee
    case ankle
    case calf
    case thigh
    case hip
    case sole
    case achilles
}
