//
//  Double+Extensions.swift
//  RunDiary
//
//  Created by 김혜지 on 10/22/25.
//

import Foundation

extension Double {
    public var to1f: String {
        String(format: "%.1f", self)
    }

    public var to2f: String {
        String(format: "%.2f", self)
    }
}
