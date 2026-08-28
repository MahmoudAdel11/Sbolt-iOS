//
//  AppInfo.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Static application metadata shown in the About section. Version is read from
/// the bundle with a mock fallback.
enum AppInfo {
    static let name = "Sbolt"
    static let developer = "Sbolt Team"

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}
