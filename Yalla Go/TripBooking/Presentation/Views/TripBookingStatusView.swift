//
//  TripBookingStatusView.swift
//  Yalla Go
//

import SwiftUI

/// Renders the booking flow for every non-idle `TripPhase`. Pure UI — it reads
/// `viewModel.phase` and sends intents (cancel / retry) only.
struct TripBookingStatusView: View {
    @ObservedObject var viewModel: TripBookingViewModel
    @State private var isShowingRatingPrompt = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Capsule()
                .fill(AppColors.borderHairline)
                .frame(width: 50, height: 6)

            content

            actions
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.phase)
        .onChange(of: viewModel.phase) { phase in
            if case .completed = phase { isShowingRatingPrompt = true }
        }
        // `onDismiss` fires however the sheet closed — Submit, Skip, or a
        // swipe-down — so it's the single place that resumes the paused
        // auto-dismiss (see TripBookingViewModel.proceedPastRatingPrompt).
        .sheet(isPresented: $isShowingRatingPrompt, onDismiss: {
            viewModel.proceedPastRatingPrompt()
        }) {
            if case let .completed(trip) = viewModel.phase {
                RatingSubmissionView(rideID: trip.id, driverName: trip.driver?.name, fare: trip.fare)
            }
        }
    }

    // MARK: - Phase content

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle:
            EmptyView()

        case .requesting:
            VStack(spacing: AppSpacing.md) {
                ProgressView()
                Text("Requesting your ride…")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("trip_requesting")

        case let .active(trip):
            ActiveTripSheet(trip: trip, onCancel: { viewModel.cancelTrip() })
                .accessibilityIdentifier("trip_active_\(trip.status.rawValue)")

        case let .completed(trip):
            VStack(spacing: AppSpacing.md) {
                statusHeader("Trip completed successfully", systemImage: "checkmark.circle.fill", tint: AppColors.successText)
                fareRow(for: trip)
            }
            .accessibilityIdentifier("trip_completed")

        case .cancelled:
            statusHeader("Trip cancelled", systemImage: "xmark.circle.fill", tint: AppColors.textMuted)
                .accessibilityIdentifier("trip_cancelled")

        case let .failed(message):
            VStack(spacing: AppSpacing.sm) {
                statusHeader("Couldn't book your trip", systemImage: "exclamationmark.triangle.fill", tint: AppColors.warningText)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("trip_failed")
        }
    }

    // MARK: - Actions

    /// Cancel now lives inside `ActiveTripSheet` (styled per the confirmed
    /// spec — full-width danger button, bottom of that sheet), so this only
    /// ever renders Retry for a failed request.
    @ViewBuilder
    private var actions: some View {
        if case .failed = viewModel.phase {
            Button {
                viewModel.retry()
            } label: {
                Text("Try Again")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .foregroundStyle(AppColors.textOnAccent)
            .background(AppColors.accent, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .accessibilityIdentifier("trip_retry_button")
        }
    }

    private func fareRow(for trip: Trip) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Text(trip.tier.description)
            Text("·")
            Text(trip.fare.toCurrency())
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundStyle(AppColors.textSecondary)
        .accessibilityIdentifier("trip_fare")
    }

    private func statusHeader(_ title: String, systemImage: String, tint: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(tint)
            .multilineTextAlignment(.center)
    }
}
