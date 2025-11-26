//
//  RunninStyle+Localization.swift
//  RunDiary
//
//  Created by Claude on 11/26/25.
//

import Foundation
import Models

extension RunninStyle {
    var localizedName: String {
        switch self {
        case .forefoot:
            return String(localized: "running_style.forefoot")
        case .midfoot:
            return String(localized: "running_style.midfoot")
        case .heelfoot:
            return String(localized: "running_style.heelfoot")
        }
    }
}
