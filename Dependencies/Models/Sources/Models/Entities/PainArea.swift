//
//  PainArea.swift
//  RunDiary
//
//  Created by Claude on 10/22/25.
//

import Foundation

/// 러닝 중 발생할 수 있는 통증 부위
public enum PainArea: String, CaseIterable, Sendable {
    case knee = "무릎"
    case ankle = "발목"
    case calf = "종아리"
    case thigh = "허벅지"
    case hip = "고관절"
    case sole = "발바닥"
    case achilles = "아킬레스건"
}
