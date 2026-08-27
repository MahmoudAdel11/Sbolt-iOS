//
//  ActiveTripSheet.swift
//  Yalla Go
//

import SwiftUI

/// Bottom-sheet content for `TripPhase.active` — driver card, call/message
/// actions, a fare/destination summary, and cancel. Pure UI: reads `trip`
/// and forwards `onCancel`; owns no state of its own.
struct ActiveTripSheet: View {
    let trip: Trip
    let onCancel: () -> Void

    private let formatter = TripFormatter()

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            if let driver = trip.driver {
                DriverCard(driver: driver, tier: trip.tier)
            } else if let driverID = trip.driverID {
                DriverCard(driver: Driver(id: driverID), tier: trip.tier)
            } else {
                lookingForDriverRow
            }

            callMessageRow

            fareDestinationSummary

            Button(role: .destructive, action: onCancel) {
                Text("Cancel Trip")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .foregroundStyle(AppColors.textOnAccent)
            .background(AppColors.danger, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .accessibilityIdentifier("trip_cancel_button")
        }
    }

    private var lookingForDriverRow: some View {
        HStack(spacing: AppSpacing.sm) {
            ProgressView()
            Text("Looking for a nearby driver…")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.accentTint, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    /// LOGIC GAP (flagged, not implemented): neither `Driver` nor the
    /// backend's `RideDriverSummary` carries a phone number or any messaging
    /// channel — there is nothing to call or message with. These render the
    /// full visual spec but are deliberately no-ops rather than faking a
    /// call/message flow with no data behind it. See this task's summary.
    private var callMessageRow: some View {
        HStack(spacing: AppSpacing.sm) {
            Button {} label: {
                Label("Call", systemImage: "phone.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .foregroundStyle(AppColors.textOnAccent)
            .background(AppColors.textPrimary, in: Capsule())
            .accessibilityIdentifier("trip_call_driver_button")
            .accessibilityHint("Calling isn't available yet")

            Button {} label: {
                Label("Message", systemImage: "message.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .foregroundStyle(AppColors.textPrimary)
            .background(AppColors.backgroundSecondary, in: Capsule())
            .accessibilityIdentifier("trip_message_driver_button")
            .accessibilityHint("Messaging isn't available yet")
        }
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
        .accessibilityIdentifier("trip_fare")
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
}

#if DEBUG
struct ActiveTripSheet_Previews: PreviewProvider {
    static var previews: some View {
        ActiveTripSheet(trip: MockTripRepository.sampleTrips()[0], onCancel: {})
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
