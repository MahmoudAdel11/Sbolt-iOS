//
//  AppColorsTests.swift
//  Yalla GoTests
//

import Testing
import SwiftUI
@testable import Sbolt

/// Confirms every `AppColors` token actually resolves to distinct light/dark
/// values (not silently falling back to one appearance in both, or crashing)
/// — an automated substitute for toggling appearance in Simulator/Preview,
/// which this environment can't drive directly.
struct AppColorsTests {

    private func rgba(_ color: Color, style: UIUserInterfaceStyle) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        let trait = UITraitCollection(userInterfaceStyle: style)
        let uiColor = UIColor(color).resolvedColor(with: trait)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    private let allTokens: [(String, Color)] = [
        ("backgroundPrimary", AppColors.backgroundPrimary),
        ("backgroundSecondary", AppColors.backgroundSecondary),
        ("backgroundSubtle", AppColors.backgroundSubtle),
        ("borderHairline", AppColors.borderHairline),
        ("textPrimary", AppColors.textPrimary),
        ("textSecondary", AppColors.textSecondary),
        ("textMuted", AppColors.textMuted),
        ("textDisabled", AppColors.textDisabled),
        ("accent", AppColors.accent),
        ("accentTextDark", AppColors.accentTextDark),
        ("accentTextSecondary", AppColors.accentTextSecondary),
        ("accentTint", AppColors.accentTint),
        ("danger", AppColors.danger),
        ("successBackground", AppColors.successBackground),
        ("successText", AppColors.successText),
        ("warningBackground", AppColors.warningBackground),
        ("warningText", AppColors.warningText),
        ("ratingGold", AppColors.ratingGold),
    ]

    @Test func everyTokenResolvesToDifferentValuesInLightAndDarkMode() {
        for (name, color) in allTokens {
            let light = rgba(color, style: .light)
            let dark = rgba(color, style: .dark)
            #expect(light != dark, "\(name) resolved identically in light and dark mode")
        }
    }

    @Test func lightModeBackgroundIsWhiteAndDarkModeIsNearBlack() {
        let light = rgba(AppColors.backgroundPrimary, style: .light)
        let dark = rgba(AppColors.backgroundPrimary, style: .dark)

        #expect(light == (1.0, 1.0, 1.0, 1.0))
        // Near-black, not pure black (per the palette's own rule - keeps
        // card surfaces distinguishable from the screen background).
        #expect(dark.0 > 0 && dark.0 < 0.1)
    }

    @Test func accentIsLighterInDarkModeThanLightMode() {
        // Dark backgrounds need a brighter accent to read clearly - never a
        // darker one - per the confirmed palette rule.
        let light = rgba(AppColors.accent, style: .light)
        let dark = rgba(AppColors.accent, style: .dark)
        let lightLuminance = 0.299 * light.0 + 0.587 * light.1 + 0.114 * light.2
        let darkLuminance = 0.299 * dark.0 + 0.587 * dark.1 + 0.114 * dark.2

        #expect(darkLuminance > lightLuminance)
    }

    @Test func hexInitializerParsesKnownValuesCorrectly() {
        let (r, g, b, a) = rgba(Color(light: "#378ADD", dark: "#378ADD"), style: .light)
        #expect(abs(r - 0x37.hexComponent) < 0.01)
        #expect(abs(g - 0x8A.hexComponent) < 0.01)
        #expect(abs(b - 0xDD.hexComponent) < 0.01)
        #expect(a == 1.0)
    }
}

private extension Int {
    var hexComponent: CGFloat { CGFloat(self) / 255.0 }
}
