//
//  DateFormatterStorage.swift
//  CommonFoundation
//
//  Created by 김혜지 on 12/4/25.
//

import Foundation

@MainActor
public enum DateFormat: String {
    /// "yyyyMMMM"
    case yearMonth = "yyyyMMMM"
    /// "HH:mm"
    case hourMinutes = "HH:mm"
    /// "E"
    case weekday = "E"
}

extension DateFormat {
    private static var storedFormatters: [String: DateFormatter] = [:]

    var formatter: DateFormatter {
        Self.getStoredFormatter(of: rawValue)
    }

    static func getStoredFormatter(of dateFormat: String) -> DateFormatter {
        if let storedFomatter = storedFormatters[dateFormat] {
            return storedFomatter
        }

        let newFormatter = Self.makeFormatter(with: dateFormat)
        storedFormatters.updateValue(newFormatter, forKey: dateFormat)
        return newFormatter
    }

    private static func makeFormatter(with dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate(dateFormat)
        return formatter
    }
}
