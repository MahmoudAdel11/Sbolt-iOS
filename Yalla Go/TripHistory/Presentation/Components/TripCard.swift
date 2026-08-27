//
//  TripCard.swift
//  Yalla Go
//

import SwiftUI

/// Reusable card summarising a single ride in any lifecycle state — shown
/// pre-accept (driver's available-ride card), post-accept (driver's active-ride
/// card), and in trip history, uniformly. `tier`/`fare` are real, frozen
/// backend fields (not client-side estimates) and are shown in all three
/// contexts; pickup/dropoff show the resolved place name when the backend
/// has one, falling back to coordinates otherwise (older rides, or a failed
/// client-side geocoding lookup at request time).
struct TripCard: View {
    let trip: Trip
    var formatter = TripFormatter()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            topRow
            fareRow
            route
            Divider()
            bottomRow
        }
        .padding(AppSpacing.lg)
        .background(AppColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Pieces

    private var topRow: some View {
        HStack(spacing: AppSpacing.sm) {
            TierBadge(tier: trip.tier, size: 24)
            Text("Ride")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            statusBadge
        }
    }

    private var statusBadge: some View {
        Text(trip.status.displayName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(statusBackground, in: Capsule())
            .foregroundStyle(statusColor)
    }

    private var fareRow: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(trip.tier.description)
            Text("·")
            Text(trip.fare.toCurrency())
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundStyle(AppColors.textSecondary)
        .accessibilityIdentifier("trip_card_fare")
    }

    private var route: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 2) {
                Image(systemName: "circle.fill").font(.system(size: 8)).foregroundStyle(AppColors.textMuted)
                Rectangle().fill(AppColors.textMuted.opacity(0.4)).frame(width: 1, height: 18)
                Image(systemName: "mappin.circle.fill").font(.system(size: 10)).foregroundStyle(AppColors.accent)
            }
            .accessibilityHidden(true)
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 10) {
                Text(formatter.placeName(trip.pickupAddress, fallback: trip.pickupCoordinate)).font(.subheadline)
                Text(formatter.placeName(trip.dropoffAddress, fallback: trip.destinationCoordinate)).font(.subheadline)
            }
            .foregroundStyle(AppColors.textPrimary)
            Spacer(minLength: 0)
        }
    }

    private var bottomRow: some View {
        Text("\(formatter.date(trip.requestedAt)) · \(formatter.time(trip.requestedAt))")
            .font(.caption)
            .foregroundStyle(AppColors.textMuted)
    }

    /// Completed/Cancelled route through the Phase 1 success/warning
    /// tokens (so they respect dark mode correctly) per this task's
    /// explicit instruction — Cancelled moves from the previous raw red to
    /// the warning (orange) token, a deliberate semantic recolor, not a bug
    /// left in place. Requested/Accepted/Ongoing (not covered by that
    /// instruction) just get the same design-system-token treatment for the
    /// in-progress states, in place of raw `.blue`/`.orange`/`.secondary`.
    private var statusColor: Color {
        switch trip.status {
        case .completed: return AppColors.successText
        case .cancelled: return AppColors.warningText
        case .ongoing:   return AppColors.accent
        case .accepted:  return AppColors.accentTextSecondary
        case .requested: return AppColors.textMuted
        }
    }

    private var statusBackground: Color {
        switch trip.status {
        case .completed: return AppColors.successBackground
        case .cancelled: return AppColors.warningBackground
        case .ongoing, .accepted: return AppColors.accentTint
        case .requested: return AppColors.backgroundSubtle
        }
    }

    private var accessibilitySummary: String {
        "Ride from \(formatter.placeName(trip.pickupAddress, fallback: trip.pickupCoordinate)) to "
            + "\(formatter.placeName(trip.dropoffAddress, fallback: trip.destinationCoordinate)), "
            + "\(formatter.date(trip.requestedAt)), \(trip.status.displayName)"
    }
}

#if DEBUG
struct TripCard_Previews: PreviewProvider {
    static var previews: some View {
        TripCard(trip: MockTripRepository.sampleTrips()[0])
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
