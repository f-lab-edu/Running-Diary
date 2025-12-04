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
    // MARK: - Error (1 key)
    /// An error occurred
    static let errorGeneric: LocalizableKey<LocalizableParameterCount0> = .init(key: "error.generic")

    // MARK: - Format (4 keys)
    /// %@km 포맷 (1 파라미터)
    static let formatKm: LocalizableKey<LocalizableParameterCount1> = .init(key: "format.km")
    /// 총 %@km 포맷 (1 파라미터)
    static let formatTotalKm: LocalizableKey<LocalizableParameterCount1> = .init(key: "format.total_km")
    /// %lld월 %lld일 다이어리 보기 포맷 (2 파라미터)
    static let formatViewDiaryDate: LocalizableKey<LocalizableParameterCount2> = .init(key: "format.view_diary_date")
    /// %@년 %@월 포맷 (2 파라미터)
    static let formatYearMonth: LocalizableKey<LocalizableParameterCount2> = .init(key: "format.year_month")

    // MARK: - HealthKit Data (3 keys)
    /// Health data access denied
    static let healthkitDataEmpty: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.data.empty")
    /// Loading fitness data!
    static let healthkitDataLoading: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.data.loading")
    /// Please allow access in Settings to fetch running data.
    static let healthkitDataPermissionMessage: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.data.permission_message")

    // MARK: - HealthKit Error (4 keys)
    /// Failed to request HealthKit authorization. Please try again later.
    static let healthkitErrorAuthorizationFailed: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.error.authorization_failed")
    /// Data not found
    static let healthkitErrorDataNotFound: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.error.data_not_found")
    /// Failed to fetch HealthKit data
    static let healthkitErrorFetchContext: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.error.fetch_context")
    /// HealthKit is not available on this device.
    static let healthkitErrorNotAvailable: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.error.not_available")

    // MARK: - HealthKit (1 key)
    /// Failed to fetch fitness data
    static let healthkitFetchFailedTitle: LocalizableKey<LocalizableParameterCount0> = .init(key: "healthkit.fetch_failed_title")

    // MARK: - Record (6 keys)
    /// Add Record
    static let recordAdd: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.add")
    /// Add Record (button)
    static let recordAddButton: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.add_button")
    /// Edit Record
    static let recordEdit: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.edit")
    /// No running records
    static let recordEmpty: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.empty")
    /// Fitness Data
    static let recordFitnessData: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.fitness_data")
    /// Write Diary
    static let recordWriteDiaryButton: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.write_diary_button")

    // MARK: - Record Error (2 keys)
    /// Failed to load record
    static let recordErrorFetchContext: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.error.fetch_context")
    /// Failed to save record
    static let recordErrorSaveContext: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.error.save_context")

    // MARK: - Record Field (25 keys)
    /// Alcohol
    static let recordFieldAlcoholLabel: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.alcohol_label")
    /// Average Cadence
    static let recordFieldCadence: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.cadence")
    /// Condition
    static let recordFieldCondition: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.condition")
    /// Distance
    static let recordFieldDistance: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.distance")
    /// Duration
    static let recordFieldDuration: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.duration")
    /// Had Meal
    static let recordFieldHasMeal: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.has_meal")
    /// Average Heart Rate
    static let recordFieldHeartRate: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.heart_rate")
    /// Exercise Intensity
    static let recordFieldIntensity: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.intensity")
    /// Please select exercise intensity!
    static let recordFieldIntensityPlaceholder: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.intensity_placeholder")
    /// Map Area
    static let recordFieldMap: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.map")
    /// Meal
    static let recordFieldMealLabel: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.meal_label")
    /// Other Notes
    static let recordFieldMemo: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.memo")
    /// Leave a note!\nEx) It was hard to run because of the wind😭
    static let recordFieldMemoPlaceholder: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.memo_placeholder")
    /// Average Pace
    static let recordFieldPace: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.pace")
    /// Pain Areas
    static let recordFieldPainAreas: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.pain_areas")
    /// Running Style
    static let recordFieldRunningStyle: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.running_style")
    /// Running Style
    static let recordFieldRunningStyleLabel: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.running_style_label")
    /// What running style did you use?
    static let recordFieldRunningStylePlaceholder: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.running_style_placeholder")
    /// Worn Shoes
    static let recordFieldShoes: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.shoes")
    /// Worn Shoes
    static let recordFieldShoesLabel: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.shoes_label")
    /// Which shoes did you wear?
    static let recordFieldShoesPlaceholder: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.shoes_placeholder")
    /// Sleep Duration
    static let recordFieldSleepDuration: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.sleep_duration")
    /// Sleep
    static let recordFieldSleepLabel: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.sleep_label")
    /// Time
    static let recordFieldTime: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.time")
    /// Had Alcohol
    static let recordFieldWasDrinking: LocalizableKey<LocalizableParameterCount0> = .init(key: "record.field.was_drinking")

    // MARK: - Repository Error (4 keys)
    /// Failed to delete record
    static let repositoryErrorDeleteFailed: LocalizableKey<LocalizableParameterCount0> = .init(key: "repository.error.delete_failed")
    /// Record not found
    static let repositoryErrorNotFound: LocalizableKey<LocalizableParameterCount0> = .init(key: "repository.error.not_found")
    /// Failed to save record
    static let repositoryErrorSaveFailed: LocalizableKey<LocalizableParameterCount0> = .init(key: "repository.error.save_failed")
    /// Failed to update record
    static let repositoryErrorUpdateFailed: LocalizableKey<LocalizableParameterCount0> = .init(key: "repository.error.update_failed")

    // MARK: - Shoe Error (2 keys)
    /// Failed to load shoes
    static let shoeErrorFetchContext: LocalizableKey<LocalizableParameterCount0> = .init(key: "shoe.error.fetch_context")
    /// Failed to fetch shoes
    static let shoeErrorFetchFailed: LocalizableKey<LocalizableParameterCount0> = .init(key: "shoe.error.fetch_failed")

    // MARK: - UI (8 keys)
    /// Back
    static let uiBack: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.back")
    /// Cancel
    static let uiCancel: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.cancel")
    /// Done
    static let uiDone: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.done")
    /// Edit
    static let uiEdit: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.edit")
    /// Go to Settings
    static let uiGoToSettings: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.go_to_settings")
    /// Save
    static let uiSave: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.save")
    /// Today
    static let uiToday: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.today")
    /// View Details
    static let uiViewDetails: LocalizableKey<LocalizableParameterCount0> = .init(key: "ui.view_details")

    // MARK: - Unit (4 keys)
    /// bpm
    static let unitBpm: LocalizableKey<LocalizableParameterCount0> = .init(key: "unit.bpm")
    /// hours
    static let unitHours: LocalizableKey<LocalizableParameterCount0> = .init(key: "unit.hours")
    /// km
    static let unitKm: LocalizableKey<LocalizableParameterCount0> = .init(key: "unit.km")
    /// spm
    static let unitSpm: LocalizableKey<LocalizableParameterCount0> = .init(key: "unit.spm")

    // MARK: - Weather (1 key)
    /// No weather data
    static let weatherNoData: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.no_data")

    // MARK: - Weather Error (5 keys)
    /// Weather API key is missing
    static let weatherErrorApiKeyMissing: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.error.api_key_missing")
    /// Weather data is unavailable
    static let weatherErrorDataUnavailable: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.error.data_unavailable")
    /// Invalid response from weather API
    static let weatherErrorInvalidResponse: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.error.invalid_response")
    /// Location is required to fetch weather data
    static let weatherErrorLocationRequired: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.error.location_required")
    /// Network error occurred
    static let weatherErrorNetworkError: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.error.network_error")

    // MARK: - Weather Field (3 keys)
    /// Humidity
    static let weatherFieldHumidity: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.field.humidity")
    /// Temperature
    static let weatherFieldTemperature: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.field.temperature")
    /// Wind Speed
    static let weatherFieldWindSpeed: LocalizableKey<LocalizableParameterCount0> = .init(key: "weather.field.wind_speed")
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
