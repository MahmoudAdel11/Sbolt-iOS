//
//  RiderInfoCard.swift
//  Yalla Go
//

import SwiftUI

/// Rider-facing counterpart to the rider side's `DriverCard` — same visual
/// language (AccentTint background, initials avatar), shown to the driver
/// during an active ride.
///
/// LOGIC GAP (flagged, not implemented): unlike the rider side, `Trip`
/// carries no rider name/rating at all — only a bare `riderID` string, and
/// the backend response has no rider-facing summary equivalent to
/// `RideDriverSummary`. This always renders the "Rider" fallback rather
/// than a real name; a real name/rating would need a new backend field and
/// DTO/domain plumbing, which is out of scope for this UI-only pass. See
/// this task's summary.
struct RiderInfoCard: View {
    let tier: RideType

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            avatar

            VStack(alignment: .leading, spacing: 2) {
                Text("Rider")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(tier.description)
                    .font(.caption)
                    .foregroundStyle(AppColors.accentTextSecondary)
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.accentTint, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(AppColors.accent)
            Text("?")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppColors.textOnAccent)
        }
        .frame(width: 44, height: 44)
        .accessibilityHidden(true)
    }
}

#if DEBUG
struct RiderInfoCard_Previews: PreviewProvider {
    static var previews: some View {
        RiderInfoCard(tier: .comfort)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
