//
//  L10n.swift
//  RunDiary
//
//  Generated localization wrapper for type-safe string access
//  SwiftGen-style structure wrapping Xcode String Catalog
//

import Foundation
import SwiftUI

// MARK: - LocalizableKey Type System

/// Format specifier 파라미터 개수를 컴파일 타임에 체크하기 위한 프로토콜
protocol LocalizableParameterCount {}

/// 파라미터 없음
struct LocalizableParameterCount0: LocalizableParameterCount {}
/// 파라미터 1개
struct LocalizableParameterCount1: LocalizableParameterCount {}
/// 파라미터 2개
struct LocalizableParameterCount2: LocalizableParameterCount {}
/// 파라미터 3개
struct LocalizableParameterCount3: LocalizableParameterCount {}
/// 파라미터 4개
struct LocalizableParameterCount4: LocalizableParameterCount {}
/// 파라미터 5개
struct LocalizableParameterCount5: LocalizableParameterCount {}

/// 타입 안전한 localization key wrapper
struct LocalizableKey<T: LocalizableParameterCount> {
    let key: String
}

// MARK: - Value Extensions (String 반환)

// periphery:ignore
extension LocalizableKey where T == LocalizableParameterCount0 {
    /// 파라미터 없는 키의 String 값
    var value: String {
        return L10n.tr(key)
    }
}

// periphery:ignore
extension LocalizableKey where T == LocalizableParameterCount1 {
    /// 1개 파라미터를 받아 포맷팅된 String 반환
    func value(_ p0: CVarArg) -> String {
        return L10n.tr(key, p0)
    }
}

// periphery:ignore
extension LocalizableKey where T == LocalizableParameterCount2 {
    /// 2개 파라미터를 받아 포맷팅된 String 반환
    func value(_ p0: CVarArg, _ p1: CVarArg) -> String {
        return L10n.tr(key, p0, p1)
    }
}

// periphery:ignore
extension LocalizableKey where T == LocalizableParameterCount3 {
    /// 3개 파라미터를 받아 포맷팅된 String 반환
    func value(_ p0: CVarArg, _ p1: CVarArg, _ p2: CVarArg) -> String {
        return L10n.tr(key, p0, p1, p2)
    }
}

// periphery:ignore
extension LocalizableKey where T == LocalizableParameterCount4 {
    /// 4개 파라미터를 받아 포맷팅된 String 반환
    func value(_ p0: CVarArg, _ p1: CVarArg, _ p2: CVarArg, _ p3: CVarArg) -> String {
        return L10n.tr(key, p0, p1, p2, p3)
    }
}

// periphery:ignore
extension LocalizableKey where T == LocalizableParameterCount5 {
    /// 5개 파라미터를 받아 포맷팅된 String 반환
    func value(_ p0: CVarArg, _ p1: CVarArg, _ p2: CVarArg, _ p3: CVarArg, _ p4: CVarArg) -> String {
        return L10n.tr(key, p0, p1, p2, p3, p4)
    }
}

// MARK: - Text Extensions (SwiftUI Text 반환)

// periphery:ignore
extension LocalizableKey where T == LocalizableParameterCount0 {
    /// 파라미터 없는 키의 SwiftUI Text
    var text: Text {
        return Text(.init(stringLiteral: key))
    }
}

// periphery:ignore
extension LocalizableKey where T == LocalizableParameterCount1 {
    /// 1개 파라미터를 받아 SwiftUI Text 반환
    func text(_ p0: CVarArg) -> Text {
        return Text(L10n.tr(key, p0))
    }
}

// periphery:ignore
extension LocalizableKey where T == LocalizableParameterCount2 {
    /// 2개 파라미터를 받아 SwiftUI Text 반환
    func text(_ p0: CVarArg, _ p1: CVarArg) -> Text {
        return Text(L10n.tr(key, p0, p1))
    }
}

// periphery:ignore
extension LocalizableKey where T == LocalizableParameterCount3 {
    /// 3개 파라미터를 받아 SwiftUI Text 반환
    func text(_ p0: CVarArg, _ p1: CVarArg, _ p2: CVarArg) -> Text {
        return Text(L10n.tr(key, p0, p1, p2))
    }
}

// periphery:ignore
extension LocalizableKey where T == LocalizableParameterCount4 {
    /// 4개 파라미터를 받아 SwiftUI Text 반환
    func text(_ p0: CVarArg, _ p1: CVarArg, _ p2: CVarArg, _ p3: CVarArg) -> Text {
        return Text(L10n.tr(key, p0, p1, p2, p3))
    }
}

// periphery:ignore
extension LocalizableKey where T == LocalizableParameterCount5 {
    /// 5개 파라미터를 받아 SwiftUI Text 반환
    func text(_ p0: CVarArg, _ p1: CVarArg, _ p2: CVarArg, _ p3: CVarArg, _ p4: CVarArg) -> Text {
        return Text(L10n.tr(key, p0, p1, p2, p3, p4))
    }
}

// MARK: - Localization Keys

enum L10n {
    // MARK: - Format
    enum Format {
        /// %@년 %@월 포맷 (2 파라미터)
        static let yearMonth: LocalizableKey<LocalizableParameterCount2> = .init(key: "format.year_month")
        /// 총 %@km 포맷 (1 파라미터)
        static let totalKm: LocalizableKey<LocalizableParameterCount1> = .init(key: "format.total_km")
        /// %lld월 %lld일 다이어리 보기 포맷 (2 파라미터)
        static let viewDiaryDate: LocalizableKey<LocalizableParameterCount2> = .init(key: "format.view_diary_date")
        /// %dkm 포맷(1 파라미터)
        static let km: LocalizableKey<LocalizableParameterCount1> = .init(key: "format.km")
    }

    // MARK: - HealthKit
    enum Healthkit {
        enum Data {
            /// Health data access denied
            static let empty: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.data.empty")
            /// Loading fitness data!
            static let loading: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.data.loading")
            /// Please allow access in Settings to fetch running data.
            static let permissionMessage: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.data.permission_message")
        }

        enum Error {
            /// Failed to request HealthKit authorization. Please try again later.
            static let authorizationFailed: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.error.authorization_failed")
            /// Data not found
            static let dataNotFound: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.error.data_not_found")
            /// Failed to fetch HealthKit data
            static let fetchContext: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.error.fetch_context")
            /// HealthKit is not available on this device.
            static let notAvailable: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.error.not_available")
        }

        /// Failed to fetch fitness data
        static let fetchFailedTitle: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.fetch_failed_title")
    }

    // MARK: - Record
    enum Record {
        /// Add Record
        static let add: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.add")
        /// Add Record (button)
        static let addButton: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.add_button")
        /// Edit Record
        static let edit: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.edit")
        /// No running records
        static let empty: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.empty")
        /// Fitness Data
        static let fitnessData: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.fitness_data")
        /// Write Diary
        static let writeDiaryButton: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.write_diary_button")

        enum Error {
            /// Failed to load record
            static let fetchContext: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.error.fetch_context")
            /// Failed to save record
            static let saveContext: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.error.save_context")
        }

        enum Field {
            /// Alcohol
            static let alcoholLabel: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.alcohol_label")
            /// Average Cadence
            static let cadence: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.cadence")
            /// Condition
            static let condition: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.condition")
            /// Distance
            static let distance: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.distance")
            /// Duration
            static let duration: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.duration")
            /// Had Meal
            static let hasMeal: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.has_meal")
            /// Average Heart Rate
            static let heartRate: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.heart_rate")
            /// Exercise Intensity
            static let intensity: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.intensity")
            /// Please select exercise intensity!
            static let intensityPlaceholder: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.intensity_placeholder")
            /// Map Area
            static let map: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.map")
            /// Meal
            static let mealLabel: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.meal_label")
            /// Other Notes
            static let memo: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.memo")
            /// Leave a note!\nEx) It was hard to run because of the wind😭
            static let memoPlaceholder: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.memo_placeholder")
            /// Average Pace
            static let pace: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.pace")
            /// Pain Areas
            static let painAreas: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.pain_areas")
            /// Running Style
            static let runningStyle: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.running_style")
            /// Running Style
            static let runningStyleLabel: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.running_style_label")
            /// What running style did you use?
            static let runningStylePlaceholder: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.running_style_placeholder")
            /// Worn Shoes
            static let shoes: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.shoes")
            /// Worn Shoes
            static let shoesLabel: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.shoes_label")
            /// Which shoes did you wear?
            static let shoesPlaceholder: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.shoes_placeholder")
            /// Sleep Duration
            static let sleepDuration: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.sleep_duration")
            /// Sleep
            static let sleepLabel: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.sleep_label")
            /// Time
            static let time: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.time")
            /// Had Alcohol
            static let wasDrinking: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.was_drinking")
        }
    }

    // MARK: - Repository
    enum Repository {
        enum Error {
            /// Failed to delete record
            static let deleteFailed: LocalizableKey<LocalizableParameterCount0> = .init(key: "repository.error.delete_failed")
            /// Record not found
            static let notFound: LocalizableKey<LocalizableParameterCount0> = .init(key: "repository.error.not_found")
            /// Failed to save record
            static let saveFailed: LocalizableKey<LocalizableParameterCount0> = .init(key: "repository.error.save_failed")
            /// Failed to update record
            static let updateFailed: LocalizableKey<LocalizableParameterCount0> = .init(key: "repository.error.update_failed")
        }
    }

    // MARK: - Shoe
    enum Shoe {
        enum Error {
            /// Failed to load shoes
            static let fetchContext: LocalizableKey<LocalizableParameterCount0> = .init(key: "shoe.error.fetch_context")
            /// Failed to fetch shoes
            static let fetchFailed: LocalizableKey<LocalizableParameterCount0> = .init(key: "shoe.error.fetch_failed")
        }
    }

    // MARK: - UI
    enum UI {
        /// Back
        static let back: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.back")
        /// Cancel
        static let cancel: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.cancel")
        /// Done
        static let done: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.done")
        /// Edit
        static let edit: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.edit")
        /// Go to Settings
        static let goToSettings: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.go_to_settings")
        /// Save
        static let save: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.save")
        /// Today
        static let today: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.today")
        /// View Details
        static let viewDetails: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.view_details")
    }

    // MARK: - Unit
    enum Unit {
        /// bpm
        static let bpm: LocalizableKey<LocalizableParameterCount0> = .init(key: "unit.bpm")
        /// hours
        static let hours: LocalizableKey<LocalizableParameterCount0> = .init(key: "unit.hours")
        /// km
        static let km: LocalizableKey<LocalizableParameterCount0> = .init(key: "unit.km")
        /// spm
        static let spm: LocalizableKey<LocalizableParameterCount0> = .init(key: "unit.spm")
    }

    // MARK: - Weather
    enum Weather {
        /// No weather data
        static let noData: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.no_data")

        enum Error {
            /// Weather API key is missing
            static let apiKeyMissing: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.error.api_key_missing")
            /// Weather data is unavailable
            static let dataUnavailable: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.error.data_unavailable")
            /// Invalid response from weather API
            static let invalidResponse: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.error.invalid_response")
            /// Location is required to fetch weather data
            static let locationRequired: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.error.location_required")
            /// Network error occurred
            static let networkError: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.error.network_error")
        }

        enum Field {
            /// Temperature
            static let temperature: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.field.temperature")
            /// Humidity
            static let humidity: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.field.humidity")
            /// Wind Speed
            static let windSpeed: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.field.wind_speed")
        }
    }

    // MARK: - Error
    enum Error {
        /// An error occurred
        static let generic: LocalizableKey<LocalizableParameterCount0> = .init(key: "error.generic")
    }
}

// MARK: - Helper

extension L10n {
    /// NSLocalizedString wrapper with format support
    static func tr(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(
            key,
            tableName: nil,
            bundle: .main,
            comment: ""
        )
        return String(format: format, locale: Locale.current, arguments: args)
    }
}
