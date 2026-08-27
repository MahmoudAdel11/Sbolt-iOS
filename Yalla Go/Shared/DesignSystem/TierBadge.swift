//
//  TierBadge.swift
//  Yalla Go
//

import SwiftUI

/// Rounded-square tier icon badge — the same icon/color treatment
/// `RideTierCard` established on the rider side, extracted here so the
/// driver side (Phase 3) can reuse it exactly instead of reimplementing it.
/// Uses the `ScooterIcon` template asset (Assets.xcassets, "Render As:
/// Template Image" — tintable via `.foregroundStyle`), not the generic
/// `scooter` SF Symbol: a purpose-made, higher-resolution glyph.
struct TierBadge: View {
    let tier: RideType
    var size: CGFloat = 44

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(backgroundColor)
            .frame(width: size, height: size)
            .overlay(
                Image("ScooterIcon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.22)
                    .foregroundStyle(AppColors.textOnAccent)
            )
    }

    /// Street: a fixed medium-dark gray, deliberately NOT `AppColors.textSecondary`
    /// (which flips to a *light* gray in dark mode) — the white icon needs a
    /// badge that stays dark in both themes. Ride: solid accent. Black: a
    /// fixed near-black, not `textPrimary` (flips to near-white in dark mode).
    private var backgroundColor: Color {
        switch tier {
        case .economy: return Self.fixedMediumGray
        case .comfort: return AppColors.accent
        case .premium: return Self.fixedNearBlack
        }
    }

    private static let fixedMediumGray = Color(red: 0.42, green: 0.42, blue: 0.42)
    private static let fixedNearBlack = Color(red: 0.08, green: 0.08, blue: 0.08)
}

#if DEBUG
struct TierBadge_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(RideType.allCases) { tier in
                TierBadge(tier: tier)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
