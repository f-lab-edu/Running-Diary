//
//  L10n.swift
//  RunDiary
//
//  Generated localization wrapper for type-safe string access
//  SwiftGen-style structure wrapping Xcode String Catalog
//

import Foundation

enum L10n {
    // MARK: - HealthKit
    enum Healthkit {
        enum Data {
            /// Health data access denied
            static let empty = String(localized: "healthkit.data.empty")
            /// Loading fitness data!
            static let loading = String(localized: "healthkit.data.loading")
            /// Please allow access in Settings to fetch running data.
            static let permissionMessage = String(localized: "healthkit.data.permission_message")
        }
        
        enum Error {
            /// Failed to request HealthKit authorization. Please try again later.
            static let authorizationFailed = String(localized: "healthkit.error.authorization_failed")
            /// Data not found
            static let dataNotFound = String(localized: "healthkit.error.data_not_found")
            /// Failed to fetch HealthKit data
            static let fetchContext = String(localized: "healthkit.error.fetch_context")
            /// HealthKit is not available on this device.
            static let notAvailable = String(localized: "healthkit.error.not_available")
        }
        
        /// Failed to fetch fitness data
        static let fetchFailedTitle = String(localized: "healthkit.fetch_failed_title")
    }
    
    // MARK: - Record
    enum Record {
        /// Add Record
        static let add = String(localized: "record.add")
        /// Add Record (button)
        static let addButton = String(localized: "record.add_button")
        /// Edit Record
        static let edit = String(localized: "record.edit")
        /// No running records
        static let empty = String(localized: "record.empty")
        /// Fitness Data
        static let fitnessData = String(localized: "record.fitness_data")
        /// Write Diary
        static let writeDiaryButton = String(localized: "record.write_diary_button")
        
        enum Error {
            /// Failed to load record
            static let fetchContext = String(localized: "record.error.fetch_context")
            /// Failed to save record
            static let saveContext = String(localized: "record.error.save_context")
        }
        
        enum Field {
            /// Alcohol
            static let alcoholLabel = String(localized: "record.field.alcohol_label")
            /// Average Cadence
            static let cadence = String(localized: "record.field.cadence")
            /// Condition
            static let condition = String(localized: "record.field.condition")
            /// Distance
            static let distance = String(localized: "record.field.distance")
            /// Duration
            static let duration = String(localized: "record.field.duration")
            /// Had Meal
            static let hasMeal = String(localized: "record.field.has_meal")
            /// Average Heart Rate
            static let heartRate = String(localized: "record.field.heart_rate")
            /// Exercise Intensity
            static let intensity = String(localized: "record.field.intensity")
            /// Please select exercise intensity!
            static let intensityPlaceholder = String(localized: "record.field.intensity_placeholder")
            /// Map Area
            static let map = String(localized: "record.field.map")
            /// Meal
            static let mealLabel = String(localized: "record.field.meal_label")
            /// Other Notes
            static let memo = String(localized: "record.field.memo")
            /// Leave a note!\nEx) It was hard to run because of the wind😭
            static let memoPlaceholder = String(localized: "record.field.memo_placeholder")
            /// Average Pace
            static let pace = String(localized: "record.field.pace")
            /// Pain Areas
            static let painAreas = String(localized: "record.field.pain_areas")
            /// Running Style
            static let runningStyle = String(localized: "record.field.running_style")
            /// Running Style
            static let runningStyleLabel = String(localized: "record.field.running_style_label")
            /// What running style did you use?
            static let runningStylePlaceholder = String(localized: "record.field.running_style_placeholder")
            /// Worn Shoes
            static let shoes = String(localized: "record.field.shoes")
            /// Worn Shoes
            static let shoesLabel = String(localized: "record.field.shoes_label")
            /// Which shoes did you wear?
            static let shoesPlaceholder = String(localized: "record.field.shoes_placeholder")
            /// Sleep Duration
            static let sleepDuration = String(localized: "record.field.sleep_duration")
            /// Sleep
            static let sleepLabel = String(localized: "record.field.sleep_label")
            /// Time
            static let time = String(localized: "record.field.time")
            /// Had Alcohol
            static let wasDrinking = String(localized: "record.field.was_drinking")
        }
    }
    
    // MARK: - Repository
    enum Repository {
        enum Error {
            /// Failed to delete record
            static let deleteFailed = String(localized: "repository.error.delete_failed")
            /// Record not found
            static let notFound = String(localized: "repository.error.not_found")
            /// Failed to save record
            static let saveFailed = String(localized: "repository.error.save_failed")
            /// Failed to update record
            static let updateFailed = String(localized: "repository.error.update_failed")
        }
    }
    
    // MARK: - Shoe
    enum Shoe {
        enum Error {
            /// Failed to load shoes
            static let fetchContext = String(localized: "shoe.error.fetch_context")
            /// Failed to fetch shoes
            static let fetchFailed = String(localized: "shoe.error.fetch_failed")
        }
    }
    
    // MARK: - UI
    enum UI {
        /// Back
        static let back = String(localized: "ui.back")
        /// Cancel
        static let cancel = String(localized: "ui.cancel")
        /// Done
        static let done = String(localized: "ui.done")
        /// Edit
        static let edit = String(localized: "ui.edit")
        /// Go to Settings
        static let goToSettings = String(localized: "ui.go_to_settings")
        /// Save
        static let save = String(localized: "ui.save")
        /// Today
        static let today = String(localized: "ui.today")
    }
    
    // MARK: - Unit
    enum Unit {
        /// bpm
        static let bpm = String(localized: "unit.bpm")
        /// hours
        static let hours = String(localized: "unit.hours")
        /// km
        static let km = String(localized: "unit.km")
        /// spm
        static let spm = String(localized: "unit.spm")
    }
    
    // MARK: - Weather
    enum Weather {
        /// No weather data
        static let noData = String(localized: "weather.no_data")

        enum Error {
            /// Weather API key is missing
            static let apiKeyMissing = String(localized: "weather.error.api_key_missing")
            /// Weather data is unavailable
            static let dataUnavailable = String(localized: "weather.error.data_unavailable")
            /// Invalid response from weather API
            static let invalidResponse = String(localized: "weather.error.invalid_response")
            /// Location is required to fetch weather data
            static let locationRequired = String(localized: "weather.error.location_required")
            /// Network error occurred
            static let networkError = String(localized: "weather.error.network_error")
        }

        enum Field {
            /// Temperature
            static let temperature = String(localized: "weather.field.temperature")
            /// Humidity
            static let humidity = String(localized: "weather.field.humidity")
            /// Wind Speed
            static let windSpeed = String(localized: "weather.field.wind_speed")
        }
    }

    // MARK: - Error
    enum Error {
        /// An error occurred
        static let generic = String(localized: "error.generic")
    }
}
