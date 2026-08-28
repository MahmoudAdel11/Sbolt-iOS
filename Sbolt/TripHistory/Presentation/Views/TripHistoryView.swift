//
//  TripHistoryView.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import SwiftUI

/// Trip History screen. Binds to `TripHistoryViewModel`; contains no business
/// logic. Renders loading / error / empty / list states and supports
/// pull-to-refresh and navigation to a trip-details placeholder.
struct TripHistoryView: View {
    @StateObject private var viewModel: TripHistoryViewModel
    @EnvironmentObject private var session: AppSessionStore

    init(dependencies: TripHistoryDependencies = TripHistoryDependencies()) {
        _viewModel = StateObject(wrappedValue: dependencies.makeTripHistoryViewModel())
    }

    var body: some View {
        content
            .navigationTitle("Trip History")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel.trips.isEmpty { viewModel.loadTripHistory() }
            }
            .onChange(of: viewModel.isSessionExpired) { expired in
                if expired { session.signOut() }
            }
    }

    // MARK: - State routing

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.trips.isEmpty {
            loadingState
        } else if let errorMessage = viewModel.errorMessage, viewModel.trips.isEmpty {
            errorState(errorMessage)
        } else if viewModel.isEmpty {
            emptyState
        } else {
            tripList
        }
    }

    private var loadingState: some View {
        ProgressView("Loading trips…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("trip_history_loading")
    }

    private var tripList: some View {
        List {
            ForEach(viewModel.trips) { trip in
                ZStack {
                    TripCard(trip: trip)
                    NavigationLink {
                        TripDetailsPlaceholderView(trip: trip)
                    } label: {
                        EmptyView()
                    }
                    .opacity(0)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("trip_row_\(trip.id)")
                .accessibilityHint("Shows trip details")
            }

            if viewModel.hasMore {
                loadMoreRow
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.refresh()
            await viewModel.activeTask?.value
        }
    }

    private var loadMoreRow: some View {
        HStack {
            Spacer()
            if viewModel.isLoadingMore {
                ProgressView()
            } else {
                Button("Load More") { viewModel.loadMore() }
                    .accessibilityIdentifier("trip_history_load_more_button")
            }
            Spacer()
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Retry") { viewModel.loadTripHistory() }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("trip_history_retry_button")
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("trip_history_error_state")
    }

    /// Mirrors the accent-tint circle empty-state treatment established in
    /// Phase 2a (`RecentTripsSection.emptyState`) — same icon-badge
    /// language, warmer copy than the previous plain "No trips yet."
    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.accentTint)
                    .frame(width: 72, height: 72)
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.accent)
            }
            Text("Ready for your first ride?")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
            Text("Trips you take will show up here.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)

            // Pre-existing no-op (empty action closure) — unchanged; this
            // task is a visual pass on the shape/color only, per its own
            // "confirm existing functionality unchanged" scope.
            Button("Book Your First Trip") { }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textOnAccent)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(AppColors.accent, in: Capsule())
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.sm)
                .accessibilityIdentifier("trip_history_book_button")
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("trip_history_empty_state")
    }
}

#if DEBUG
struct TripHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TripHistoryView()
        }
        .navigationViewStyle(.stack)
        .environmentObject(AppSessionStore())
    }
}
#endif
