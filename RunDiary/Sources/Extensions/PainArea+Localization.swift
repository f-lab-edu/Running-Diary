//
//  PainArea+Localization.swift
//  RunDiary
//
//  Created by Claude on 11/26/25.
//

import Foundation
import Models

extension PainArea {
    var localizedName: String {
        switch self {
        case .knee:
            return String(localized: "pain_area.knee")
        case .ankle:
            return String(localized: "pain_area.ankle")
        case .calf:
            return String(localized: "pain_area.calf")
        case .thigh:
            return String(localized: "pain_area.thigh")
        case .hip:
            return String(localized: "pain_area.hip")
        case .sole:
            return String(localized: "pain_area.sole")
        case .achilles:
            return String(localized: "pain_area.achilles")
        }
    }
}
