//
//  TimeInterval+Extensions.swift
//  CommonFoundation
//
//  Created by 김혜지 on 10/28/25.
//

import Foundation

extension TimeInterval {
    public var formatted: String {
        var seconds = Int(self)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        seconds %= 60

        if hours > 0 {
            return String(format: "%d시간 %0d분 %0d초", hours, minutes, seconds)
        } else {
            return String(format: "%d분 %0d초", minutes, seconds)
        }
    }
}
