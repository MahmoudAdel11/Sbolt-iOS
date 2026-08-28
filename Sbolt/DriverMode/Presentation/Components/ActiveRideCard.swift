//
//  ActiveRideCard.swift
//  Yalla Go
//

import SwiftUI

/// Driver-side active-ride card — mirrors the rider-side `ActiveTripSheet`'s
/// visual language (rider info card, fare/destination summary, one action
/// button). Pure UI: reads `trip`, forwards `onStart`/`onComplete`.
///
/// Business logic is unchanged: exactly one button ever shows, driven by
/// `trip.status` (`.accepted` → Start, anything else → Complete) — the same
/// require-start-before-complete rule `DriverModeViewModel` already
/// enforces. This view only decides which button's *style* to draw, never
/// which one is eligible to show.
struct ActiveRideCard: View {
    let trip: Trip
    let isStarting: Bool
    let isCompleting: Bool
    let onStart: () -> Void
    let onComplete: () -> Void

    private let formatter = TripFormatter()

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            RiderInfoCard(tier: trip.tier)

            fareDestinationSummary

            if trip.status == .accepted {
                actionButton(title: "Start Trip", isLoading: isStarting,
                            background: AppColors.accent, action: onStart)
                    .accessibilityIdentifier("driver_start_ride_button")
            } else {
                actionButton(title: "Complete Ride", isLoading: isCompleting,
                            background: AppColors.solidDark, action: onComplete)
                    .accessibilityIdentifier("driver_complete_ride_button")
            }
        }
        .accessibilityIdentifier("driver_active_ride")
    }

    private var fareDestinationSummary: some View {
        VStack(spacing: 0) {
            summaryRow(label: "Fare", value: trip.fare.toCurrency())
            Divider().background(AppColors.borderHairline)
            summaryRow(
                label: "Destination",
                value: formatter.placeName(trip.dropoffAddress, fallback: trip.destinationCoordinate)
            )
        }
        .padding(AppSpacing.md)
        .background(AppColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppColors.textMuted)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
        }
        .padding(.vertical, AppSpacing.sm)
    }

    private func actionButton(title: String, isLoading: Bool, background: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(AppColors.textOnAccent)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .foregroundStyle(AppColors.textOnAccent)
        .background(background, in: Capsule())
        .disabled(isLoading)
    }
}

#if DEBUG
struct ActiveRideCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppSpacing.xl) {
            ActiveRideCard(trip: MockTripRepository.sampleTrips()[0], isStarting: false, isCompleting: false,
                          onStart: {}, onComplete: {})
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
