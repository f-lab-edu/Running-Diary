//
//  SettingsFeatureTests.swift
//  RunDiaryTests
//
//  Created by Claude on 12/15/25.
//

import ComposableArchitecture
import Testing
@testable import RunDiary

@Suite("SettingsFeature")
struct SettingsFeatureTests {

    @Test("개인정보처리방침 URL이 올바르게 구성됨")
    func privacyPolicyURL_isCorrect() {
        // Given
        let item = SettingsFeature.SettingsItem.privacyPolicy

        // When
        let url = item.url

        // Then
        #expect(url.contains("privacy-policy"))
        #expect(url.hasPrefix("https://apps.kimhyeji.dev/run-diary/"))
    }

    @Test("이용약관 URL이 올바르게 구성됨")
    func termsOfServiceURL_isCorrect() {
        // Given
        let item = SettingsFeature.SettingsItem.termsOfService

        // When
        let url = item.url

        // Then
        #expect(url.contains("use-of-terms"))
        #expect(url.hasPrefix("https://apps.kimhyeji.dev/run-diary/"))
    }

    @Test("언어별 URL 분기 처리 확인")
    func urlLanguageLocalization_works() {
        // Given
        let privacyURL = SettingsFeature.SettingsItem.privacyPolicy.url
        let termsURL = SettingsFeature.SettingsItem.termsOfService.url

        // Then - 한국어, 영어, 일본어 중 하나로 끝나야 함
        let validLanguages = ["ko/", "en/", "ja/"]
        let hasValidPrivacyLanguage = validLanguages.contains { privacyURL.hasSuffix($0) }
        let hasValidTermsLanguage = validLanguages.contains { termsURL.hasSuffix($0) }

        #expect(hasValidPrivacyLanguage)
        #expect(hasValidTermsLanguage)
    }
}
