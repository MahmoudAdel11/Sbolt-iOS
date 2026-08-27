//
//  DriverCard.swift
//  Yalla Go
//

import SwiftUI

/// Reusable card showing whatever driver details are actually available.
/// The backend only ever exposes a bare `driver_id`— every rich field is
/// optional, so this renders graceful fallbacks ("Driver assigned", an
/// initials-less circle) instead of leaving gaps where a name/rating/vehicle
/// would go.
struct DriverCard: View {
    let driver: Driver
    let tier: RideType

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            avatar

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppSpacing.xs) {
                    Text(driver.name ?? "Driver assigned")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    if let rating = driver.rating {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(AppColors.ratingGold)
                        Text(ratingText(rating))
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                Text(tier.description)
                    .font(.caption)
                    .foregroundStyle(AppColors.accentTextSecondary)
            }

            Spacer()

            if driver.vehicleColor != nil || driver.plateNumber != nil {
                VStack(alignment: .trailing, spacing: 2) {
                    if let vehicleColor = driver.vehicleColor {
                        Text(vehicleColor)
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    if let plateNumber = driver.plateNumber {
                        Text(plateNumber)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.accentTextDark)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.accentTint, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(AppColors.accent)
            Text(initials)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppColors.textOnAccent)
        }
        .frame(width: 44, height: 44)
        .accessibilityHidden(true)
    }

    /// Up to 2 letters from the driver's first/last name; a generic "?"
    /// substitute when no name is known yet.
    private var initials: String {
        guard let name = driver.name, !name.isEmpty else { return "?" }
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    /// "4.8 (12 rides)" when a count is known and non-zero; a bare "4.8"
    /// otherwise (e.g. a driver with no ratings yet, or the count didn't decode).
    private func ratingText(_ rating: Double) -> String {
        guard let count = driver.ratingCount, count > 0 else {
            return String(format: "%.1f", rating)
        }
        return String(format: "%.1f (%d ride%@)", rating, count, count == 1 ? "" : "s")
    }
}

#if DEBUG
struct DriverCard_Previews: PreviewProvider {
    static var previews: some View {
        DriverCard(
            driver: Driver(id: "driver-1", name: "Jane Driver", rating: 4.8, ratingCount: 12,
                          vehicleColor: "White", plateNumber: "ABC-123"),
            tier: .comfort
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
