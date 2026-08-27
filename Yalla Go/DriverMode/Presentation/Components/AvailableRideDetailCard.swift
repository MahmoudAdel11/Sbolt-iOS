//
//  AvailableRideDetailCard.swift
//  Yalla Go
//

import SwiftUI

/// Bottom sheet shown when the driver taps an available-ride pin on the map
/// (the only mechanism that exists for accepting a ride — there is no
/// separate list-row/detail-view flow). Pure UI: reads `ride`, forwards
/// `onAccept`.
struct AvailableRideDetailCard: View {
    let ride: Trip
    let isAccepting: Bool
    let onAccept: () -> Void

    private let formatter = TripFormatter()

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Capsule()
                .fill(AppColors.borderHairline)
                .frame(width: 50, height: 6)

            HStack(spacing: AppSpacing.md) {
                TierBadge(tier: ride.tier, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(ride.tier.description)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Ride request")
                        .font(.caption)
                        .foregroundStyle(AppColors.textMuted)
                }
                Spacer()
                Text(ride.fare.toCurrency())
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            addressSummary

            Button(action: onAccept) {
                ZStack {
                    Text("Accept")
                        .font(.subheadline.weight(.semibold))
                        .opacity(isAccepting ? 0 : 1)
                    if isAccepting {
                        ProgressView().tint(AppColors.textOnAccent)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 52)
            }
            .foregroundStyle(AppColors.textOnAccent)
            .background(AppColors.accent, in: Capsule())
            .disabled(isAccepting)
            .accessibilityIdentifier("driver_accept_button_\(ride.id)")
        }
        .padding(AppSpacing.lg)
        .background(
            BottomSheetShape(radius: 20)
                .fill(AppColors.backgroundPrimary)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)
        .accessibilityIdentifier("driver_available_ride_\(ride.id)")
    }

    /// Same resolved-address-with-coordinate-fallback pattern already used
    /// on the rider side (`TripFormatter.placeName`) — reused as-is, not
    /// reimplemented.
    private var addressSummary: some View {
        VStack(spacing: 0) {
            summaryRow(label: "Pickup", value: formatter.placeName(ride.pickupAddress, fallback: ride.pickupCoordinate))
            Divider().background(AppColors.borderHairline)
            summaryRow(label: "Dropoff", value: formatter.placeName(ride.dropoffAddress, fallback: ride.destinationCoordinate))
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
}

/// Rounds only the top-left and top-right corners so the sheet merges
/// seamlessly with the map above it — mirrors `RideRequestView`'s own
/// private shape of the same name/purpose (kept separate since Swift has no
/// shared-internal-shape convention here and this is a small, self-contained shape).
private struct BottomSheetShape: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

#if DEBUG
struct AvailableRideDetailCard_Previews: PreviewProvider {
    static var previews: some View {
        AvailableRideDetailCard(ride: MockTripRepository.sampleTrips()[0], isAccepting: false, onAccept: {})
            .previewLayout(.sizeThatFits)
    }
}
#endif
