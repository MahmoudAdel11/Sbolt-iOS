//
//  RecentTripsSection.swift
//  Yalla Go
//

import SwiftUI

/// Home's idle-state content below the search bar: up to 3 recent trips
/// (tapping one starts a new ride to that destination, reusing the exact
/// same "select a known coordinate as the destination" path already used by
/// `SavedPlacePickerView`), or an empty state for a rider with no history yet.
///
/// Reuses `TripHistoryViewModel`/`GetTripHistoryUseCase` unchanged — the
/// same data `TripHistoryView` shows, just capped to 3 items here. No new
/// business logic.
struct RecentTripsSection: View {
    @ObservedObject var viewModel: TripHistoryViewModel
    let onSelectDestination: (Trip) -> Void

    private let formatter = TripFormatter()

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if !recentTrips.isEmpty {
                Text("Recent trips")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.lg)

                VStack(spacing: AppSpacing.sm) {
                    ForEach(recentTrips) { trip in
                        Button {
                            onSelectDestination(trip)
                        } label: {
                            row(for: trip)
                        }
                        .accessibilityIdentifier("home_recent_trip_\(trip.id)")
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            } else if !viewModel.isLoading {
                emptyState
            }
        }
    }

    private var recentTrips: [Trip] {
        Array(viewModel.trips.prefix(3))
    }

    private func row(for trip: Trip) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(AppColors.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                // The backend has no place-name field - see the destination
                // coordinate formatted the same way TripCard/TripHistory show
                // it, rather than inventing a fake address.
                Text(formatter.coordinate(trip.destinationCoordinate))
                    .font(.body)
                    .foregroundStyle(AppColors.textPrimary)
                Text(formatter.date(trip.requestedAt))
                    .font(.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.accentTint)
                    .frame(width: 72, height: 72)
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.accent)
            }
            Text("Start your journey")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
            Text("Where do you want to go today?")
                .font(.subheadline)
                .foregroundStyle(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.xl)
        .accessibilityIdentifier("home_recent_trips_empty_state")
    }
}
