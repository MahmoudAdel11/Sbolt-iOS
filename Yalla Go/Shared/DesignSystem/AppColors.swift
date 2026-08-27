//
//  AppColors.swift
//  Yalla Go
//

import SwiftUI

/// Centralized design-system color tokens for the whole app. Every new/
/// redesigned screen should reference a token here, not a raw `Color(...)`
/// call or hex literal — this is the single place the light/dark palette
/// (and any future re-theming) is defined.
///
/// Backed by `Color(light:dark:)` below rather than Asset Catalog color
/// sets: this codebase had no established colorset pattern to build on
/// (only the default, never-customized `AccentColor`), and spelling exact
/// hex values out in Swift is explicit and reviewable in a diff, unlike
/// per-swatch Asset Catalog JSON edited outside Xcode's color picker.
enum AppColors {

    // MARK: - Backgrounds

    /// Primary screen background. Light: pure white. Dark: near-black —
    /// deliberately not pure black, so card surfaces (`backgroundSecondary`)
    /// still read as a distinct layer instead of vanishing into the screen.
    static let backgroundPrimary = Color(light: "#FFFFFF", dark: "#0D0D0D")
    /// Card / secondary surface background.
    static let backgroundSecondary = Color(light: "#F7F7F5", dark: "#1C1C1C")
    /// Subtle background for inactive/map-adjacent areas.
    static let backgroundSubtle = Color(light: "#F2F2F0", dark: "#1C1C1C")

    // MARK: - Borders

    /// Hairline dividers/borders. Brightened in dark mode — a light-mode
    /// hairline this faint would nearly disappear on a dark background.
    static let borderHairline = Color(light: "#ECECEA", dark: "#2A2A2A")

    // MARK: - Text

    static let textPrimary = Color(light: "#0A0A0A", dark: "#F5F5F5")
    static let textSecondary = Color(light: "#6B6B6B", dark: "#A3A3A0")
    static let textMuted = Color(light: "#9A9A97", dark: "#7A7A77")
    static let textDisabled = Color(light: "#C4C4C1", dark: "#4A4A47")

    // MARK: - Accent (blue) — primary actions, selected states

    /// The accent itself: an accessory color, not a wallpaper — used for
    /// primary actions and selected states, never large fills.
    static let accent = Color(light: "#378ADD", dark: "#5B9EE8")
    /// Dark text sitting on an `accentTint` background.
    static let accentTextDark = Color(light: "#0C447C", dark: "#BFE0FF")
    /// Secondary text sitting on an `accentTint` background.
    static let accentTextSecondary = Color(light: "#185FA5", dark: "#9FCBF2")
    /// Light accent wash, used as a background behind accent-colored text/icons.
    static let accentTint = Color(light: "#E6F1FB", dark: "#16283D")
    /// Text/icon color for content sitting directly on a solid `accent`
    /// (or other saturated, dark-enough) fill — always near-white regardless
    /// of theme, since the fill itself already carries the light/dark contrast.
    static let textOnAccent = Color(light: "#FFFFFF", dark: "#FFFFFF")

    // MARK: - Semantic status colors

    /// Destructive actions (cancel, delete). Slightly desaturated in dark
    /// mode — the light-mode value reads as an oversaturated "glow" on a
    /// dark background otherwise.
    static let danger = Color(light: "#FF2D2D", dark: "#E5484D")
    static let successBackground = Color(light: "#EAF3DE", dark: "#1D2A14")
    static let successText = Color(light: "#3B6D11", dark: "#8FCB4E")
    static let warningBackground = Color(light: "#FAECE7", dark: "#2E1C14")
    static let warningText = Color(light: "#993C1D", dark: "#E08A5E")
    static let ratingGold = Color(light: "#D4A017", dark: "#E8B94A")
}

// MARK: - Dynamic hex color support

extension Color {
    /// A color that resolves to `light` in Light Mode and `dark` in Dark
    /// Mode, each given as a `"#RRGGBB"` hex string. The one place hex
    /// parsing happens — every `AppColors` token is built on this.
    init(light: String, dark: String) {
        self = Color(uiColor: UIColor { traitCollection in
            UIColor(hex: traitCollection.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    /// Parses a `"#RRGGBB"` (or `"RRGGBB"`) hex string. Malformed input
    /// (shouldn't happen — every call site here is a hardcoded literal)
    /// falls back to opaque black rather than crashing.
    convenience init(hex: String) {
        let hexDigits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgbValue: UInt64 = 0
        Scanner(string: hexDigits).scanHexInt64(&rgbValue)
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
