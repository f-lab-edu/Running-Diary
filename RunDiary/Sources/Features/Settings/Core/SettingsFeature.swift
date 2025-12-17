//
//  SettingsFeature.swift
//  RunDiary
//
//  Created by Claude on 12/15/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SettingsFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable {
        // 간단한 화면이므로 별도 상태 불필요
    }

    // MARK: - Action

    enum Action {
        case settingsItemTapped(SettingsItem)
    }

    // MARK: - SettingsItem

    enum SettingsItem: String, CaseIterable, Identifiable {
        case privacyPolicy
        case termsOfService

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .privacyPolicy: return L10n.settingsPrivacyPolicy.value
            case .termsOfService: return L10n.settingsTermsOfService.value
            }
        }

        var url: String {
            let languageCode = Locale.current.language.languageCode?.identifier ?? "ko"
            let supportedLanguage: String

            // 지원 언어: ko, en, ja (기본값: ko)
            switch languageCode {
            case "en": supportedLanguage = "en"
            case "ja": supportedLanguage = "ja"
            default: supportedLanguage = "ko"
            }

            switch self {
            case .privacyPolicy:
                return "https://apps.kimhyeji.dev/run-diary/privacy-policy/\(supportedLanguage)/"
            case .termsOfService:
                return "https://apps.kimhyeji.dev/run-diary/use-of-terms/\(supportedLanguage)/"
            }
        }
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .settingsItemTapped(item):
                AppLogger.settings.debug("settingsItemTapped - item: \(item.displayName)")
                return .run { _ in
                    await MainActor.run {
                        URLOpener.open(url: item.url)
                    }
                }
            }
        }
    }
}
