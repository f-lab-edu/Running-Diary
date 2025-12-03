//
//  Date+Extension.swift
//  CommonFoundation
//
//  Created by 김혜지 on 11/10/25.
//

import Foundation

extension Date {
    @MainActor
    public func formattedString(dateFormat: DateFormat) -> String {
        return dateFormat.formatter.string(from: self)
    }
}
