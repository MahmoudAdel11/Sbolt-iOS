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
        VStack(spacing: 16) {
            Capsule()
                .foregroundColor(Color(.systemGray5))
                .frame(width: 50, height: 6)

            content

            actions
        }
        .padding()
        .padding(.bottom, 12)
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
                RatingSubmissionView(rideID: trip.id)
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
            VStack(spacing: 12) {
                ProgressView()
                Text("Requesting your ride…")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("trip_requesting")

        case let .active(trip):
            VStack(spacing: 10) {
                statusHeader(activeStatusTitle(for: trip), systemImage: activeStatusIcon(for: trip), tint: .blue)
                if let driver = trip.driver {
                    DriverCard(driver: driver, statusText: trip.status.displayName)
                } else if let driverID = trip.driverID {
                    // Assigned but the embedded summary didn't decode/arrive —
                    // degrade to the bare-ID fallback rather than a blank gap.
                    DriverCard(driver: Driver(id: driverID), statusText: trip.status.displayName)
                } else {
                    ProgressView()
                }
            }
            .accessibilityIdentifier("trip_active_\(trip.status.rawValue)")

        case .completed:
            statusHeader("Trip completed successfully", systemImage: "flag.checkered", tint: .green)
                .accessibilityIdentifier("trip_completed")

        case .cancelled:
            statusHeader("Trip cancelled", systemImage: "xmark.circle.fill", tint: .secondary)
                .accessibilityIdentifier("trip_cancelled")

        case let .failed(message):
            VStack(spacing: 8) {
                statusHeader("Couldn't book your trip", systemImage: "exclamationmark.triangle.fill", tint: .orange)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("trip_failed")
        }
    }

    private func activeStatusTitle(for trip: Trip) -> String {
        switch trip.status {
        case .requested: return "Looking for a nearby driver…"
        case .accepted:  return "Your driver is on the way"
        case .ongoing:   return "Your trip has started"
        case .completed, .cancelled: return trip.status.displayName
        }
    }

    private func activeStatusIcon(for trip: Trip) -> String {
        switch trip.status {
        case .requested: return "magnifyingglass"
        case .accepted:  return "car.fill"
        case .ongoing:   return "location.fill"
        case .completed: return "flag.checkered"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var actions: some View {
        if viewModel.isCancellable {
            Button(role: .destructive) {
                viewModel.cancelTrip()
            } label: {
                Text("Cancel Trip")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .accessibilityIdentifier("trip_cancel_button")
        } else if case .failed = viewModel.phase {
            Button {
                viewModel.retry()
            } label: {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .foregroundStyle(.white)
            }
            .accessibilityIdentifier("trip_retry_button")
        }
    }

    private func statusHeader(_ title: String, systemImage: String, tint: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(tint)
            .multilineTextAlignment(.center)
    }
}
