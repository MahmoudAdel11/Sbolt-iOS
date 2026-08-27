//
//  DriverStatusCard.swift
//  Yalla Go
//

import SwiftUI

/// Floating top card on the Drive screen: an online/offline toggle row, and
/// (same card, hairline-divided) a rating/tier row. Pure UI — reads state,
/// forwards the toggle intent via a `Binding`.
struct DriverStatusCard: View {
    @Binding var isOnline: Bool
    let isDisabled: Bool
    /// `nil` when no driver rating data is available (see this task's
    /// summary — there is currently no source for the driver's own rating
    /// anywhere in the app). The row still renders with just the tier when
    /// this is nil, rather than showing a fabricated placeholder.
    let rating: (average: Double, count: Int)?
    let scooterTier: RideType?

    var body: some View {
        VStack(spacing: 0) {
            toggleRow

            if rating != nil || scooterTier != nil {
                Divider().background(AppColors.borderHairline)
                infoRow
            }
        }
        .background(AppColors.backgroundPrimary, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
    }

    private var toggleRow: some View {
        Toggle(isOn: $isOnline) {
            HStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(isOnline ? AppColors.successText : AppColors.textDisabled)
                    .frame(width: 10, height: 10)
                Text(isOnline ? "Online" : "Offline")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .disabled(isDisabled)
        .padding(AppSpacing.md)
        .accessibilityIdentifier("driver_online_toggle")
    }

    private var infoRow: some View {
        HStack(spacing: AppSpacing.sm) {
            if let rating {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(AppColors.ratingGold)
                Text("\(String(format: "%.1f", rating.average)) (\(rating.count))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }

            if rating != nil && scooterTier != nil {
                Circle()
                    .fill(AppColors.textDisabled)
                    .frame(width: 3, height: 3)
            }

            if let scooterTier {
                TierBadge(tier: scooterTier, size: 20)
                Text(scooterTier.description)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

#if DEBUG
struct DriverStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppSpacing.lg) {
            DriverStatusCard(isOnline: .constant(true), isDisabled: false,
                            rating: (4.8, 132), scooterTier: .comfort)
            DriverStatusCard(isOnline: .constant(false), isDisabled: false,
                            rating: nil, scooterTier: .comfort)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .previewLayout(.sizeThatFits)
    }
}
#endif
