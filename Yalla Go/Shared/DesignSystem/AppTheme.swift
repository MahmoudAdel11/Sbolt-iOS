//
//  AppTheme.swift
//  Yalla Go
//

import SwiftUI

/// Corner-radius tokens for the redesign. Existing screens use a scattered
/// mix of 6/8/10/12/14/16/20pt radii today — going forward, new/redesigned
/// UI should pick one of these two, not a new one-off value.
enum AppRadius {
    /// Standard radius for cards, sheets, and grouped content surfaces.
    static let card: CGFloat = 14
    /// Fully-rounded ("pill") shape for primary buttons and chip-style controls.
    static let pill: CGFloat = 25
}

/// Spacing scale for the redesign. Existing screens already cluster loosely
/// around 4/8/12/16/24/32pt paddings today (with some one-off outliers like
/// 6/10/14/32) — this names that scale explicitly so new UI reuses it
/// instead of picking arbitrary values.
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

/// Typography for the redesign. The app uses the system font (SF Pro) via
/// SwiftUI's built-in semantic text styles (`.headline`, `.subheadline`,
/// `.body`, `.caption`, etc.) almost everywhere already — that's kept as-is
/// deliberately (free Dynamic Type support, and it already reads as
/// consistent). No custom font family is introduced here.
///
/// The only inconsistency worth naming is the handful of large ad-hoc
/// `.system(size: 40/48/56, ...)` displays used for big empty-state icons
/// and stat numbers — three different fixed sizes with no clear reasoning
/// for which one. These two tokens consolidate that down to one size for
/// each of the two actual use cases seen.
enum AppFont {
    /// Large empty-state / illustrative icon size.
    static let displayIcon: Font = .system(size: 48, weight: .regular)
    /// Bold display numbers/headlines that need to be bigger than `.largeTitle`.
    static let displayBold: Font = .system(size: 40, weight: .bold)
}
