//
//  AppearanceMode.swift
//  Yalla Go
//

import SwiftUI

/// The app's appearance preference — a genuine 3-state control, not a
/// binary "dark mode on/off" toggle: `.system` follows the device's
/// system-wide appearance and lives alongside it correctly (the previous
/// on/off toggle had no way to express "follow the system," which is what a
/// well-behaved iOS app should default to). Stored under a single
/// `@AppStorage` key so the app root and the Settings screen both read/write
/// the same persisted value and stay in sync live.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "appearanceMode"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// `nil` for `.system` — `.preferredColorScheme(nil)` is exactly what
    /// tells SwiftUI/the OS to decide, restoring normal system-following
    /// behavior rather than forcing anything.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
