//
//  DriverHomeView.swift
//  Yalla Go
//

import SwiftUI

/// The driver-mode "Drive" screen: online/offline toggle, the polled
/// available-rides list (or the active-ride card once one is accepted).
/// Binds to `DriverModeViewModel`; contains no business logic.
struct DriverHomeView: View {
    @StateObject private var viewModel: DriverModeViewModel
    @EnvironmentObject private var session: AppSessionStore

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
    }

    // MARK: - Sections

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                statusToggle
                if let raceConditionMessage = viewModel.raceConditionMessage {
                    InlineBanner(message: raceConditionMessage, tone: .neutral)
                        .accessibilityIdentifier("driver_race_condition_banner")
                }
                if let actionErrorMessage = viewModel.actionErrorMessage {
                    InlineBanner(message: actionErrorMessage, tone: .error)
                        .accessibilityIdentifier("driver_action_error_banner")
                }

                if let activeRide = viewModel.activeRide {
                    activeRideCard(activeRide)
                } else if viewModel.isOnline {
                    availableRidesSection
                } else {
                    offlineState
                }
            }
            .padding(16)
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

    @ViewBuilder
    private var availableRidesSection: some View {
        if viewModel.isLoadingRides && viewModel.rides.isEmpty {
            ProgressView("Looking for rides…")
                .padding(32)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("driver_rides_loading")
        } else if let ridesErrorMessage = viewModel.ridesErrorMessage, viewModel.rides.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text(ridesErrorMessage)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("driver_rides_error_state")
        } else if viewModel.rides.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "car.2")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text("No rides available right now")
                    .font(.title3).bold()
                Text("New requests appear here automatically.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("driver_rides_empty_state")
        } else {
            VStack(spacing: 12) {
                ForEach(viewModel.rides) { ride in
                    availableRideRow(ride)
                }
            }
        }
    }

    private func availableRideRow(_ ride: Trip) -> some View {
        VStack(spacing: 12) {
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
        .accessibilityIdentifier("driver_available_ride_\(ride.id)")
    }

    private func activeRideCard(_ trip: Trip) -> some View {
        VStack(spacing: 12) {
            TripCard(trip: trip)
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
