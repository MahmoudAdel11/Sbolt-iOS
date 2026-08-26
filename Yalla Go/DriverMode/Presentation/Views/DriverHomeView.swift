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
            VStack(spacing: 16) {
                statusToggle
                bannerStack

                if let activeRide = viewModel.activeRide {
                    activeRideCard(activeRide)
                } else {
                    offlineState
                }
            }
            .padding(16)
        }
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
            VStack(spacing: 12) {
                statusToggle
                bannerStack
                ridesStatusPill
            }
            .padding(16)
        }
        .overlay(alignment: .bottomTrailing) {
            recenterButton
                .padding(.trailing, 16)
                .padding(.bottom, selectedRide == nil ? 24 : 200)
        }
        .overlay(alignment: .bottom) {
            if let selectedRide {
                rideDetailCard(selectedRide)
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
        if let raceConditionMessage = viewModel.raceConditionMessage {
            InlineBanner(message: raceConditionMessage, tone: .neutral)
                .accessibilityIdentifier("driver_race_condition_banner")
        }
        if let actionErrorMessage = viewModel.actionErrorMessage {
            InlineBanner(message: actionErrorMessage, tone: .error)
                .accessibilityIdentifier("driver_action_error_banner")
        }
    }

    private var statusToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: onlineBinding) {
                Label(viewModel.isOnline ? "Online" : "Offline",
                      systemImage: viewModel.isOnline ? "circle.fill" : "circle")
                    .foregroundStyle(viewModel.isOnline ? .green : .secondary)
            }
            .disabled(viewModel.isUpdatingStatus || viewModel.activeRide != nil)
            .accessibilityIdentifier("driver_online_toggle")

            if let statusErrorMessage = viewModel.statusErrorMessage {
                InlineBanner(message: statusErrorMessage, tone: .error)
                    .accessibilityIdentifier("driver_status_error_banner")
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var offlineState: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("You're offline")
                .font(.title2).bold()
            Text("Go online to see nearby ride requests.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("driver_offline_state")
    }

    /// Small status pill overlaid on the map — keeps the loading/error/empty
    /// states from Phase 2a's list, without covering the whole map the way
    /// a full-screen state card would.
    @ViewBuilder
    private var ridesStatusPill: some View {
        if viewModel.isLoadingRides && viewModel.rides.isEmpty {
            statusPill(text: "Looking for rides…", systemImage: nil)
                .accessibilityIdentifier("driver_rides_loading")
        } else if let ridesErrorMessage = viewModel.ridesErrorMessage, viewModel.rides.isEmpty {
            statusPill(text: ridesErrorMessage, systemImage: "exclamationmark.triangle")
                .accessibilityIdentifier("driver_rides_error_state")
        } else if viewModel.rides.isEmpty {
            statusPill(text: "No rides available right now", systemImage: "car.2")
                .accessibilityIdentifier("driver_rides_empty_state")
        }
    }

    private func statusPill(text: String, systemImage: String?) -> some View {
        HStack(spacing: 8) {
            if systemImage != nil {
                Image(systemName: systemImage!)
            } else {
                ProgressView().controlSize(.small)
            }
            Text(text).font(.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.systemBackground), in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 6)
    }

    private var recenterButton: some View {
        Button {
            recenterTrigger = true
        } label: {
            Image(systemName: "location.fill")
                .font(.title3)
                .foregroundColor(.black)
                .padding()
                .background(.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 6)
        }
        .accessibilityLabel("Recenter map")
        .accessibilityIdentifier("driver_map_recenter_button")
    }

    private func rideDetailCard(_ ride: Trip) -> some View {
        VStack(spacing: 12) {
            Capsule()
                .foregroundColor(Color(.systemGray5))
                .frame(width: 50, height: 6)
            TripCard(trip: ride)
            Button {
                viewModel.accept(rideID: ride.id)
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isAccepting {
                        ProgressView()
                    } else {
                        Text("Accept")
                    }
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isAccepting)
            .accessibilityIdentifier("driver_accept_button_\(ride.id)")
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .accessibilityIdentifier("driver_available_ride_\(ride.id)")
    }

    private func activeRideCard(_ trip: Trip) -> some View {
        VStack(spacing: 12) {
            TripCard(trip: trip)
            // Start is now REQUIRED before completion (reversed from this
            // session's earlier "both available while accepted" design) —
            // only one action is ever shown at a time: Start while .accepted,
            // Complete only once .ongoing. This makes reaching
            // DriverError.rideNotStarted structurally unreachable through
            // normal use, not just handled after the fact.
            if trip.status == .accepted {
                Button {
                    viewModel.startActiveRide()
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isStarting {
                            ProgressView()
                        } else {
                            Text("Start Trip")
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isStarting)
                .accessibilityIdentifier("driver_start_ride_button")
            } else {
                Button {
                    viewModel.completeActiveRide()
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isCompleting {
                            ProgressView()
                        } else {
                            Text("Complete Ride")
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isCompleting)
                .accessibilityIdentifier("driver_complete_ride_button")
            }
        }
        .accessibilityIdentifier("driver_active_ride")
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
