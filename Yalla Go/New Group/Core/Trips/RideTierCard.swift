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
            badge(size: 36)
            Text(tier.description)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
            Text(price.toCurrency())
                .font(.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(AppSpacing.sm)
        .frame(width: 84)
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

    /// Street: neutral gray. Ride: solid accent (the recommended/default
    /// tier). Black: near-black. Uses an SF Symbol rather than the legacy
    /// `yallaGoXIcon`/`yallaGo-black` brand images: those assets aren't
    /// template-rendered, so they can't take a tint to sit legibly on every
    /// badge color/theme combination the way a symbol can.
    private func badge(size: CGFloat) -> some View {
        ZStack {
            Circle().fill(badgeColor)
            Image(systemName: "car.fill")
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(AppColors.textOnAccent)
        }
        .frame(width: size, height: size)
    }

    private var badgeColor: Color {
        switch tier {
        case .economy: return AppColors.textSecondary
        case .comfort: return AppColors.accent
        case .premium: return AppColors.textPrimary
        }
    }
}

/// Short rider-facing tagline per tier — presentation-only copy, kept in the
/// view layer rather than on `RideType` itself since it has no bearing on
/// pricing/backend-mapping logic.
private extension RideType {
    var tagline: String {
        switch self {
        case .economy: return "Affordable everyday rides"
        case .comfort: return "More room, extra comfort"
        case .premium: return "Top-tier rides, top-rated drivers"
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
