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
        List(viewModel.trips) { trip in
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
        .listStyle(.plain)
        .refreshable {
            viewModel.refresh()
            await viewModel.activeTask?.value
        }
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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("No trips yet")
                .font(.title2).bold()
            Text("Your completed trips will appear here.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Book Your First Trip") { }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("trip_history_book_button")
        }
        .padding(24)
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
    }
}
#endif
