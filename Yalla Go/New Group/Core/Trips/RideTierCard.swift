//
//  RideTierCard.swift
//  Yalla Go
//

import SwiftUI

/// One tier option in the ride-request bottom sheet. Two layouts share the
/// same badge/color logic so the collapsed and expanded sheet states never
/// drift apart: `.compact` (icon + name + price, for the horizontally
/// scrolling collapsed row) and `.expanded` (icon + name + description +
/// price, full width, for the dragged-up sheet).
struct RideTierCard: View {
    enum Style {
        case compact
        case expanded
    }

    let tier: RideType
    let price: Double
    let isSelected: Bool
    var style: Style = .expanded

    var body: some View {
        switch style {
        case .compact: compactBody
        case .expanded: expandedBody
        }
    }

    // MARK: - Compact (collapsed sheet)

    private var compactBody: some View {
        VStack(spacing: AppSpacing.xs) {
            badge(size: 40)
            Text(tier.description)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
            Text(price.toCurrency())
                .font(.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(
            isSelected ? AppColors.accentTint : AppColors.backgroundSecondary,
            in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(isSelected ? AppColors.accent : .clear, lineWidth: 1.5)
        )
    }

    // MARK: - Expanded (dragged-up sheet)

    private var expandedBody: some View {
        HStack(spacing: AppSpacing.md) {
            badge(size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(tier.description)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(tier.tagline)
                    .font(.caption)
                    .foregroundStyle(AppColors.textMuted)
            }

            Spacer()

            Text(price.toCurrency())
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(AppSpacing.md)
        .background(
            isSelected ? AppColors.accentTint : AppColors.backgroundSecondary,
            in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(isSelected ? AppColors.accent : .clear, lineWidth: 1.5)
        )
    }

    // MARK: - Shared

    /// Rounded-square icon badge. Uses the `ScooterIcon` template asset
    /// (Assets.xcassets, "Render As: Template Image" — tintable via
    /// `.foregroundStyle` just like an SF Symbol) rather than the generic
    /// `scooter` SF Symbol: it's a purpose-made, higher-resolution glyph
    /// with more detail than the system symbol at these badge sizes.
    ///
    /// Colors are exactly the 3 confirmed per-tier values, not a
    /// hierarchical/shaded rendering — hierarchical mode would introduce
    /// multiple opacities of one color, which contradicts "exactly 3 colors,
    /// one flat color per tier."
    private func badge(size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(badgeBackground)
            .frame(width: size, height: size)
            .overlay(
                Image("ScooterIcon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.22)
                    .foregroundStyle(iconColor)
            )
    }

    /// Street: a fixed medium-dark gray, deliberately NOT `AppColors.textSecondary`
    /// (which flips to a *light* gray in dark mode — see its own definition)
    /// — the white icon needs a badge that stays dark in both themes, not
    /// one that inverts and loses contrast exactly when dark mode is on.
    /// Ride: solid accent. Black: a fixed near-black, not `textPrimary`
    /// (which flips to near-white in dark mode for the same reason).
    private var badgeBackground: Color {
        switch tier {
        case .economy: return Self.fixedMediumGray
        case .comfort: return AppColors.accent
        case .premium: return Self.fixedNearBlack
        }
    }

    /// Fixed (non-theme-flipping) badge tones — flagged design choice: these
    /// intentionally don't use `Color(light:dark:)` tokens, since the whole
    /// point is to stay constant across appearance changes so the white
    /// icon on top always has enough contrast.
    private static let fixedMediumGray = Color(red: 0.42, green: 0.42, blue: 0.42)
    private static let fixedNearBlack = Color(red: 0.08, green: 0.08, blue: 0.08)

    /// All 3 tiers render the icon in `textOnAccent` (white): every badge
    /// background above is dark/saturated enough for it to stay legible —
    /// including Street's darkened neutral badge, which exists specifically
    /// so this can stay white rather than needing a 4th icon-color token.
    private var iconColor: Color {
        AppColors.textOnAccent
    }
}

/// Short rider-facing tagline per tier — presentation-only copy, kept in the
/// view layer rather than on `RideType` itself since it has no bearing on
/// pricing/backend-mapping logic.
private extension RideType {
    var tagline: String {
        switch self {
        case .economy: return "Affordable everyday rides"
        case .comfort: return "Comfortable and reliable"
        case .premium: return "Premium scooters"
        }
    }
}

#if DEBUG
struct RideTierCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HStack(spacing: AppSpacing.sm) {
                ForEach(RideType.allCases) { tier in
                    RideTierCard(tier: tier, price: tier.baseFare, isSelected: tier == .comfort, style: .compact)
                }
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Compact")

            VStack(spacing: AppSpacing.sm) {
                ForEach(RideType.allCases) { tier in
                    RideTierCard(tier: tier, price: tier.baseFare, isSelected: tier == .comfort, style: .expanded)
                }
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Expanded")
        }
    }
}
#endif
