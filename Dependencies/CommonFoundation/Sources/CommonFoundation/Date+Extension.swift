//
//  Date+Extension.swift
//  CommonFoundation
//
//  Created by 김혜지 on 11/10/25.
//

import Foundation

extension Date {
    public var formmatedTime: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
}
