//
//  Double+Extensions.swift
//  RunDiary
//
//  Created by 김혜지 on 10/22/25.
//

import Foundation

extension Double {
    public var to1f: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.roundingMode = .down
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }

    public var to2f: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.roundingMode = .down
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}
