//
//  TripBookingStatusView.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import SwiftUI

/// Renders the booking flow for every non-idle `TripPhase`. Pure UI — it reads
/// `viewModel.phase` and sends intents (cancel / retry) only.
struct TripBookingStatusView: View {
    @ObservedObject var viewModel: TripBookingViewModel

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
    }

    // MARK: - Phase content

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle:
            EmptyView()

        case .searching:
            VStack(spacing: 12) {
                ProgressView()
                Text("Searching for nearby drivers…")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("trip_searching")

        case let .driverFound(driver):
            VStack(spacing: 10) {
                statusHeader("Driver found", systemImage: "checkmark.circle.fill", tint: .green)
                DriverCard(driver: driver)
            }
            .accessibilityIdentifier("trip_driver_found")

        case let .driverArriving(driver):
            VStack(spacing: 10) {
                statusHeader("Your driver is on the way", systemImage: "car.fill", tint: .blue)
                DriverCard(driver: driver,
                           statusText: "Arriving in \(driver.estimatedArrivalMinutes) min")
            }
            .accessibilityIdentifier("trip_driver_arriving")

        case let .tripStarted(driver):
            VStack(spacing: 10) {
                statusHeader("Your trip has started", systemImage: "location.fill", tint: .blue)
                DriverCard(driver: driver)
            }
            .accessibilityIdentifier("trip_started")

        case .tripCompleted:
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
