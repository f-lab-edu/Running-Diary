//
//  L10n.swift
//  HealthKitService
//
//  Created by 김혜지 on 11/1/25.
//

enum L10n {
    enum Error {
        static var notAvailable: String {
            String(localized: "healthkit.error.not_available")
        }
        static var authorizationFailed: String {
            String(localized: "healthkit.error.authorization_failed")
        }
        static var dataNotFound: String {
            String(localized: "healthkit.error.data_not_found")
        }
    }
}
