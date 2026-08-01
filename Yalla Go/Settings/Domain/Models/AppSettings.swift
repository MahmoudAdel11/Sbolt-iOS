//
//  AppSettings.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// User-configurable application settings. Backend-agnostic and contains only
/// what the Settings feature needs today.
struct AppSettings: Equatable {
    var isDarkModeEnabled: Bool
    var isPushNotificationsEnabled: Bool
    var language: String

    static let `default` = AppSettings(isDarkModeEnabled: false,
                                       isPushNotificationsEnabled: true,
                                       language: "English")
}
