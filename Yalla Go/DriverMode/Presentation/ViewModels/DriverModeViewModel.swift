//
//  DriverModeViewModel.swift
//  Yalla Go
//

import Foundation
import Combine

/// Drives the driver-mode "Drive" screen: online/offline status, the
/// available-rides list (polled every 5s while online and on-screen), and
/// accepting/completing a ride. Views only read published state and send intents.
///
/// Polling is gated on two independently-toggled conditions —
/// `isOnline` and "screen is active" — recomputed by `refreshPolling()`
/// whenever either changes, matching the confirmed decision that polling
/// must stop the moment either becomes false (mode switch, backgrounding, or
/// manually going offline).
@MainActor
final class DriverModeViewModel: ObservableObject {

    @Published private(set) var isOnline = false
    @Published private(set) var isUpdatingStatus = false
    @Published private(set) var statusErrorMessage: String?

    @Published private(set) var rides: [Trip] = []
    @Published private(set) var isLoadingRides = false
    @Published private(set) var ridesErrorMessage: String?

    @Published private(set) var activeRide: Trip?
    @Published private(set) var isAccepting = false
    @Published private(set) var isStarting = false
    @Published private(set) var isCompleting = false
    @Published private(set) var actionErrorMessage: String?
    /// Set on a 409 from `acceptRide` — a non-alarming, distinct message from
    /// `actionErrorMessage` so the view can render it without error styling.
    @Published private(set) var raceConditionMessage: String?

    /// `true` once a `.sessionExpired` error is caught. The view observes
    /// this and signs the session out — the ViewModel itself has no access
    /// to `AppSessionStore` (same pattern as `TripBookingViewModel`).
    @Published private(set) var isSessionExpired = false

    private let setDriverStatusUseCase: SetDriverStatusUseCase
    private let pollAvailableRidesUseCase: PollAvailableRidesUseCase
    private let acceptRideUseCase: AcceptRideUseCase
    private let startRideUseCase: StartRideUseCase
    private let completeRideUseCase: CompleteRideUseCase
    private let errorPresenter: DriverErrorPresenter

    private var didConfigure = false
    private var isScreenActive = false
    private var location: Coordinate?

    /// Exposed read-only so callers/tests can await/cancel in-flight work.
    private(set) var statusTask: Task<Void, Never>?
    private(set) var pollingTask: Task<Void, Never>?
    private(set) var actionTask: Task<Void, Never>?

    var isPolling: Bool { pollingTask != nil }

    init(setDriverStatusUseCase: SetDriverStatusUseCase,
         pollAvailableRidesUseCase: PollAvailableRidesUseCase,
         acceptRideUseCase: AcceptRideUseCase,
         startRideUseCase: StartRideUseCase,
         completeRideUseCase: CompleteRideUseCase,
         errorPresenter: DriverErrorPresenter = DriverErrorPresenter()) {
        self.setDriverStatusUseCase = setDriverStatusUseCase
        self.pollAvailableRidesUseCase = pollAvailableRidesUseCase
        self.acceptRideUseCase = acceptRideUseCase
        self.startRideUseCase = startRideUseCase
        self.completeRideUseCase = completeRideUseCase
        self.errorPresenter = errorPresenter
    }

    deinit {
        statusTask?.cancel()
        pollingTask?.cancel()
        actionTask?.cancel()
    }

    /// Seeds `isOnline` from the session's last backend-fetched
    /// `driverProfile.isOnline` (from `/auth/me`) rather than assuming
    /// `false` — so reopening driver mode reflects real persisted state, not
    /// just this screen instance's own memory. Only takes effect once; later
    /// calls (e.g. a second `.task` firing) never clobber a toggle already in
    /// flight.
    func configure(initialIsOnline: Bool) {
        guard !didConfigure else { return }
        didConfigure = true
        isOnline = initialIsOnline
    }

    func screenDidAppear(location: Coordinate?) {
        isScreenActive = true
        if let location { self.location = location }
        refreshPolling()
    }

    func screenDidDisappear() {
        isScreenActive = false
        refreshPolling()
    }

    func locationDidChange(_ coordinate: Coordinate) {
        location = coordinate
        // A location arriving after online+active but before any fix was
        // available should start polling now, not wait for the next toggle.
        refreshPolling()
    }

    /// Toggles online/offline. Ignored while another status update is in
    /// flight, or while on an active ride (must complete it first).
    func setOnline(_ value: Bool) {
        guard !isUpdatingStatus, activeRide == nil else { return }
        isUpdatingStatus = true
        statusErrorMessage = nil
        statusTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isUpdatingStatus = false }
            do {
                let user = try await self.setDriverStatusUseCase.execute(isOnline: value)
                self.isOnline = user.driverProfile?.isOnline ?? value
                self.refreshPolling()
            } catch is CancellationError {
            } catch {
                self.statusErrorMessage = self.errorPresenter.message(for: error)
                if case DriverError.sessionExpired = error { self.isSessionExpired = true }
            }
        }
    }

    /// Accepts an available ride. On a 409 — another driver got there first,
    /// or the rider cancelled it — shows `raceConditionMessage` (an accurate
    /// one for whichever actually happened) and drops it from the list
    /// rather than a generic error. Both outcomes behave identically besides
    /// the message: the ride is removed from `rides` either way.
    func accept(rideID: String) {
        guard !isAccepting, activeRide == nil else { return }
        isAccepting = true
        actionErrorMessage = nil
        raceConditionMessage = nil
        actionTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isAccepting = false }
            do {
                let trip = try await self.acceptRideUseCase.execute(rideID: rideID)
                self.rides.removeAll { $0.id == rideID }
                self.activeRide = trip
                self.refreshPolling() // stops: an active ride pauses browsing
            } catch let error as DriverError where error == .rideNoLongerAvailable || error == .rideCancelledByRider {
                self.raceConditionMessage = self.errorPresenter.message(for: error)
                self.rides.removeAll { $0.id == rideID }
            } catch is CancellationError {
            } catch {
                self.actionErrorMessage = self.errorPresenter.message(for: error)
                if case DriverError.sessionExpired = error { self.isSessionExpired = true }
            }
        }
    }

    /// Marks the current active ride as underway. Purely advisory — never a
    /// prerequisite for `completeActiveRide()`, which works from either
    /// `.accepted` or `.ongoing`.
    func startActiveRide() {
        guard let trip = activeRide, !isStarting else { return }
        isStarting = true
        actionErrorMessage = nil
        actionTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isStarting = false }
            do {
                let updated = try await self.startRideUseCase.execute(rideID: trip.id)
                self.activeRide = updated
            } catch is CancellationError {
            } catch {
                self.actionErrorMessage = self.errorPresenter.message(for: error)
                if case DriverError.sessionExpired = error { self.isSessionExpired = true }
            }
        }
    }

    /// Completes the current active ride, returning to browsing.
    func completeActiveRide() {
        guard let trip = activeRide, !isCompleting else { return }
        isCompleting = true
        actionErrorMessage = nil
        actionTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isCompleting = false }
            do {
                _ = try await self.completeRideUseCase.execute(rideID: trip.id)
                self.activeRide = nil
                self.refreshPolling() // resumes browsing now that the ride ended
            } catch is CancellationError {
            } catch {
                self.actionErrorMessage = self.errorPresenter.message(for: error)
                if case DriverError.sessionExpired = error { self.isSessionExpired = true }
            }
        }
    }

    func clearRaceConditionMessage() { raceConditionMessage = nil }
    func clearActionError() { actionErrorMessage = nil }
    func clearStatusError() { statusErrorMessage = nil }

    // MARK: - Polling

    private func refreshPolling() {
        let shouldPoll = isOnline && isScreenActive && activeRide == nil
        guard shouldPoll, let location else {
            pollingTask?.cancel()
            pollingTask = nil
            return
        }
        guard pollingTask == nil else { return } // already polling this location/state

        isLoadingRides = true
        ridesErrorMessage = nil
        pollingTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await batch in self.pollAvailableRidesUseCase.execute(near: location) {
                    guard !Task.isCancelled else { return }
                    self.isLoadingRides = false
                    self.rides = batch
                }
            } catch is CancellationError {
            } catch {
                guard !Task.isCancelled else { return }
                self.isLoadingRides = false
                self.ridesErrorMessage = self.errorPresenter.message(for: error)
                if case DriverError.sessionExpired = error { self.isSessionExpired = true }
                self.pollingTask = nil
            }
        }
    }
}
