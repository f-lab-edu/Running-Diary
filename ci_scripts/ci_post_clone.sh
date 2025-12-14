#!/bin/sh

# Xcode Cloud에서 Swift 매크로를 자동으로 신뢰하도록 설정
# 이 스크립트는 저장소를 클론한 후 실행됩니다.

echo "Enabling Swift macro trust for Xcode Cloud..."

# Swift 패키지의 매크로들을 신뢰하도록 설정
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

echo "Swift macros have been enabled successfully."
