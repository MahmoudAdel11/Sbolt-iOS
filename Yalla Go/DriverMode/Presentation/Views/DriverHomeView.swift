//
//  DriverHomeView.swift
//  Yalla Go
//

import SwiftUI

/// The driver-mode "Drive" screen: online/offline toggle, an interactive map
/// of polled available rides (or the active-ride card once one is
/// accepted). Binds to `DriverModeViewModel`; contains no business logic.
struct DriverHomeView: View {
    @StateObject private var viewModel: DriverModeViewModel
    @EnvironmentObject private var session: AppSessionStore
    @State private var selectedRideID: String?
    @State private var recenterTrigger = false

    init(dependencies: DriverModeDependencies = DriverModeDependencies()) {
        _viewModel = StateObject(wrappedValue: dependencies.makeDriverModeViewModel())
    }

    var body: some View {
        content
            .navigationTitle("Drive")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                viewModel.configure(initialIsOnline: session.currentUser?.driverProfile?.isOnline ?? false)
                if let location = LocationManager.shared.userLocation {
                    viewModel.screenDidAppear(location: Coordinate(latitude: location.latitude,
                                                                    longitude: location.longitude))
                } else {
                    viewModel.screenDidAppear(location: nil)
                }
            }
            .onDisappear {
                viewModel.screenDidDisappear()
            }
            .onReceive(LocationManager.shared.$userLocation) { location in
                guard let location else { return }
                viewModel.locationDidChange(Coordinate(latitude: location.latitude, longitude: location.longitude))
            }
            .onChange(of: viewModel.isSessionExpired) { expired in
                if expired { session.signOut() }
            }
            // Covers both outcomes of an accept attempt: success removes the
            // ride from `rides` (Phase 2a), and a 409 race-loss also removes
            // it — either way the sheet should just quietly go away rather
            // than dangle on a ride that's no longer selectable.
            .onChange(of: viewModel.rides) { rides in
                if let selectedRideID, !rides.contains(where: { $0.id == selectedRideID }) {
                    self.selectedRideID = nil
                }
            }
            .background(AppColors.backgroundPrimary)
    }

    // MARK: - Layout

    @ViewBuilder
    private var content: some View {
        if viewModel.activeRide == nil && viewModel.isOnline {
            mapLayout
        } else {
            scrollLayout
        }
    }

    /// Offline and active-ride states, unchanged from Phase 2a's list-based
    /// layout — only the online-and-browsing state became a map.
    private var scrollLayout: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                statusCard
                bannerStack

                if let activeRide = viewModel.activeRide {
                    ActiveRideCard(
                        trip: activeRide,
                        isStarting: viewModel.isStarting,
                        isCompleting: viewModel.isCompleting,
                        onStart: { viewModel.startActiveRide() },
                        onComplete: { viewModel.completeActiveRide() }
                    )
                } else {
                    offlineState
                }
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.backgroundPrimary)
    }

    private var mapLayout: some View {
        AvailableRidesMapViewRepresentable(
            rides: viewModel.rides,
            selectedRide: selectedRide,
            recenterTrigger: $recenterTrigger,
            onSelectRide: { id in selectedRideID = id }
        )
        .ignoresSafeArea(edges: .bottom)
        .overlay(alignment: .top) {
            VStack(spacing: AppSpacing.md) {
                statusCard
                bannerStack
                ridesStatusPill
            }
            .padding(AppSpacing.lg)
        }
        .overlay(alignment: .bottomTrailing) {
            recenterButton
                .padding(.trailing, AppSpacing.lg)
                .padding(.bottom, selectedRide == nil ? 24 : 260)
        }
        .overlay(alignment: .bottom) {
            if let selectedRide {
                AvailableRideDetailCard(
                    ride: selectedRide,
                    isAccepting: viewModel.isAccepting,
                    onAccept: { viewModel.accept(rideID: selectedRide.id) }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedRideID)
    }

    private var selectedRide: Trip? {
        guard let selectedRideID else { return nil }
        return viewModel.rides.first { $0.id == selectedRideID }
    }

    // MARK: - Pieces

    @ViewBuilder
    private var bannerStack: some View {
        // Previously nested inside the toggle card itself; moved here
        // (same accessibility identifier preserved) now that `DriverStatusCard`
        // is a pure presentational component with no view-model error wiring.
        if let statusErrorMessage = viewModel.statusErrorMessage {
            InlineBanner(message: statusErrorMessage, tone: .error)
                .accessibilityIdentifier("driver_status_error_banner")
        }
        if let raceConditionMessage = viewModel.raceConditionMessage {
            InlineBanner(message: raceConditionMessage, tone: .neutral)
                .accessibilityIdentifier("driver_race_condition_banner")
        }
        if let actionErrorMessage = viewModel.actionErrorMessage {
            InlineBanner(message: actionErrorMessage, tone: .error)
                .accessibilityIdentifier("driver_action_error_banner")
        }
    }

    /// LOGIC GAP (flagged, not implemented): `rating` is always `nil` — there
    /// is no source anywhere in the app for the driver's own average
    /// rating/count (`DriverProfile` has no rating field, and
    /// `DriverModeViewModel` never touches `RatingRepository`). The card
    /// still renders correctly with just the scooter tier; see this task's
    /// summary. `scooterTier` IS real data, already available on the
    /// session's driver profile.
    private var statusCard: some View {
        DriverStatusCard(
            isOnline: onlineBinding,
            isDisabled: viewModel.isUpdatingStatus || viewModel.activeRide != nil,
            rating: nil,
            scooterTier: session.currentUser?.driverProfile?.scooterType
        )
    }

    /// Mirrors the empty-state visual language established in Phase 2a
    /// (`RecentTripsSection.emptyState`): accent-tint circle icon, headline,
    /// muted subtitle.
    private var offlineState: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.accentTint)
                    .frame(width: 72, height: 72)
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.accent)
            }
            Text("You're offline")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
            Text("Go online to see nearby ride requests")
                .font(.subheadline)
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.xl)
        .accessibilityIdentifier("driver_offline_state")
    }

    /// Small status pill overlaid on the map — keeps the loading/error/empty
    /// states from Phase 2a's list, without covering the whole map the way
    /// a full-screen state card would.
    ///
    /// NOTE (scope): the confirmed design described "available ride rows
    /// below the map," but the current online-and-browsing state is
    /// map-pin-based, not a scrollable row list — going online replaces the
    /// list entirely with `AvailableRidesMapViewRepresentable` (map pins +
    /// a single-selection bottom sheet on tap). Introducing a parallel rows
    /// list under the map would be a real interaction/architecture change,
    /// not a visual one, so it's out of this UI-only pass — see this task's
    /// summary. This pill (and `AvailableRideDetailCard` above) are the
    /// actual available-ride UI that exists today, restyled per the confirmed
    /// tokens.
    @ViewBuilder
    private var ridesStatusPill: some View {
        if viewModel.isLoadingRides && viewModel.rides.isEmpty {
            statusPill(text: "Looking for rides…", systemImage: nil)
                .accessibilityIdentifier("driver_rides_loading")
        } else if let ridesErrorMessage = viewModel.ridesErrorMessage, viewModel.rides.isEmpty {
            statusPill(text: ridesErrorMessage, systemImage: "exclamationmark.triangle")
                .accessibilityIdentifier("driver_rides_error_state")
        } else if viewModel.rides.isEmpty {
            statusPill(text: "No rides available right now", systemImage: "mappin.slash")
                .accessibilityIdentifier("driver_rides_empty_state")
        }
    }

    private func statusPill(text: String, systemImage: String?) -> some View {
        HStack(spacing: AppSpacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(AppColors.accent)
            } else {
                ProgressView().controlSize(.small)
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.backgroundPrimary, in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 6)
    }

    private var recenterButton: some View {
        Button {
            recenterTrigger = true
        } label: {
            Image(systemName: "location.fill")
                .font(.title3)
                .foregroundStyle(AppColors.textPrimary)
                .padding(AppSpacing.md)
                .background(AppColors.backgroundPrimary, in: Circle())
                .shadow(color: .black.opacity(0.3), radius: 6)
        }
        .accessibilityLabel("Recenter map")
        .accessibilityIdentifier("driver_map_recenter_button")
    }

    // MARK: - Bindings

    private var onlineBinding: Binding<Bool> {
        Binding(get: { viewModel.isOnline },
                set: { viewModel.setOnline($0) })
    }
}

#if DEBUG
struct DriverHomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DriverHomeView()
        }
        .navigationViewStyle(.stack)
        .environmentObject(AppSessionStore())
    }
}
#endif
