//
//  DriverModeViewModelTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Yalla_Go

@MainActor
struct DriverModeViewModelTests {

    private func makeSUT(spy: DriverRepositorySpy, pollInterval: TimeInterval = 0) -> DriverModeViewModel {
        DriverModeViewModel(
            setDriverStatusUseCase: SetDriverStatusUseCase(repository: spy),
            pollAvailableRidesUseCase: PollAvailableRidesUseCase(repository: spy, interval: pollInterval),
            acceptRideUseCase: AcceptRideUseCase(repository: spy),
            completeRideUseCase: CompleteRideUseCase(repository: spy)
        )
    }

    /// Polls a synchronous condition on the current (main) actor without a
    /// real sleep tied to the 5s polling interval — just enough slack for the
    /// injected zero-interval polling `Task` to run its next iteration.
    private func waitUntil(timeout: TimeInterval = 1.0, _ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            await Task.yield()
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    // MARK: - Status toggle

    @Test func setOnlineSuccessUpdatesIsOnline() async {
        let spy = DriverRepositorySpy(setOnlineStatusResult: .success(.driverStub))
        let sut = makeSUT(spy: spy)

        sut.setOnline(true)
        await sut.statusTask?.value

        #expect(sut.isOnline == true)
        #expect(sut.statusErrorMessage == nil)
    }

    @Test func setOnlineFailurePublishesError() async {
        let spy = DriverRepositorySpy(setOnlineStatusResult: .failure(DriverError.networkUnavailable))
        let sut = makeSUT(spy: spy)

        sut.setOnline(true)
        await sut.statusTask?.value

        #expect(sut.isOnline == false)
        #expect(sut.statusErrorMessage == "No internet connection. Please try again.")
    }

    @Test func sessionExpiredOnStatusUpdateSetsFlag() async {
        let spy = DriverRepositorySpy(setOnlineStatusResult: .failure(DriverError.sessionExpired))
        let sut = makeSUT(spy: spy)

        sut.setOnline(true)
        await sut.statusTask?.value

        #expect(sut.isSessionExpired == true)
    }

    // MARK: - Polling start/stop

    @Test func pollingStartsWhenOnlineAndScreenActiveAndYieldsRides() async {
        let spy = DriverRepositorySpy(fetchAvailableRidesResult: .success([.driverStub]))
        let sut = makeSUT(spy: spy)

        sut.screenDidAppear(location: Coordinate(latitude: 30, longitude: 31))
        sut.setOnline(true)
        await sut.statusTask?.value

        #expect(sut.isPolling == true)
        await waitUntil { !sut.rides.isEmpty }
        #expect(sut.rides.count == 1)
    }

    @Test func doesNotPollWhileOfflineEvenIfScreenActive() async {
        let spy = DriverRepositorySpy()
        let sut = makeSUT(spy: spy)

        sut.screenDidAppear(location: Coordinate(latitude: 30, longitude: 31))

        #expect(sut.isPolling == false)
    }

    @Test func doesNotPollWhileOnlineIfScreenNotActive() async {
        let spy = DriverRepositorySpy()
        let sut = makeSUT(spy: spy)

        sut.setOnline(true)
        await sut.statusTask?.value

        #expect(sut.isPolling == false)
    }

    @Test func pollingStopsWhenScreenBecomesInactive() async {
        let spy = DriverRepositorySpy(fetchAvailableRidesResult: .success([.driverStub]))
        let sut = makeSUT(spy: spy)
        sut.screenDidAppear(location: Coordinate(latitude: 30, longitude: 31))
        sut.setOnline(true)
        await sut.statusTask?.value
        await waitUntil { sut.isPolling }

        sut.screenDidDisappear()

        #expect(sut.isPolling == false)
    }

    @Test func pollingStopsWhenGoingOffline() async {
        let spy = DriverRepositorySpy(fetchAvailableRidesResult: .success([.driverStub]))
        let sut = makeSUT(spy: spy)
        sut.screenDidAppear(location: Coordinate(latitude: 30, longitude: 31))
        sut.setOnline(true)
        await sut.statusTask?.value
        await waitUntil { sut.isPolling }

        sut.setOnline(false)
        await sut.statusTask?.value

        #expect(sut.isPolling == false)
    }

    // MARK: - Accept

    @Test func acceptSuccessSetsActiveRideAndRemovesFromListAndPausesPolling() async {
        let spy = DriverRepositorySpy(fetchAvailableRidesResult: .success([.driverStub]),
                                       acceptRideResult: .success(.driverStub))
        let sut = makeSUT(spy: spy)
        sut.screenDidAppear(location: Coordinate(latitude: 30, longitude: 31))
        sut.setOnline(true)
        await sut.statusTask?.value
        await waitUntil { !sut.rides.isEmpty }
        // Stops the zero-interval polling loop before accepting, so a
        // still-in-flight poll can't re-add the just-accepted ride to
        // `rides` after the accept handler removes it (a race that would
        // never occur with the real 5s interval, only with interval=0 here).
        sut.screenDidDisappear()

        sut.accept(rideID: Trip.driverStub.id)
        await sut.actionTask?.value

        #expect(sut.activeRide == .driverStub)
        #expect(!sut.rides.contains { $0.id == Trip.driverStub.id })
        #expect(sut.isPolling == false)
    }

    @Test func acceptConflictShowsRaceConditionMessageNotGenericError() async {
        let spy = DriverRepositorySpy(fetchAvailableRidesResult: .success([.driverStub]),
                                       acceptRideResult: .failure(DriverError.rideNoLongerAvailable))
        let sut = makeSUT(spy: spy)
        sut.screenDidAppear(location: Coordinate(latitude: 30, longitude: 31))
        sut.setOnline(true)
        await sut.statusTask?.value
        await waitUntil { !sut.rides.isEmpty }
        sut.screenDidDisappear() // see comment above — avoids the same poll race

        sut.accept(rideID: Trip.driverStub.id)
        await sut.actionTask?.value

        #expect(sut.raceConditionMessage == "This ride was just accepted by another driver.")
        #expect(sut.actionErrorMessage == nil)
        #expect(sut.activeRide == nil)
        #expect(!sut.rides.contains { $0.id == Trip.driverStub.id })
    }

    @Test func acceptConflictShowsCancelledByRiderMessageDistinctFromTakenByAnotherDriver() async {
        let spy = DriverRepositorySpy(fetchAvailableRidesResult: .success([.driverStub]),
                                       acceptRideResult: .failure(DriverError.rideCancelledByRider))
        let sut = makeSUT(spy: spy)
        sut.screenDidAppear(location: Coordinate(latitude: 30, longitude: 31))
        sut.setOnline(true)
        await sut.statusTask?.value
        await waitUntil { !sut.rides.isEmpty }
        sut.screenDidDisappear()

        sut.accept(rideID: Trip.driverStub.id)
        await sut.actionTask?.value

        #expect(sut.raceConditionMessage == "This ride was cancelled by the rider.")
        #expect(sut.actionErrorMessage == nil)
        #expect(sut.activeRide == nil)
        #expect(!sut.rides.contains { $0.id == Trip.driverStub.id })
    }

    // MARK: - Complete

    @Test func completeActiveRideClearsActiveRide() async {
        let spy = DriverRepositorySpy(fetchAvailableRidesResult: .success([.driverStub]),
                                       acceptRideResult: .success(.driverStub),
                                       completeRideResult: .success(.driverStub))
        let sut = makeSUT(spy: spy)
        sut.screenDidAppear(location: Coordinate(latitude: 30, longitude: 31))
        sut.setOnline(true)
        await sut.statusTask?.value
        await waitUntil { !sut.rides.isEmpty }
        sut.accept(rideID: Trip.driverStub.id)
        await sut.actionTask?.value

        sut.completeActiveRide()
        await sut.actionTask?.value

        #expect(sut.activeRide == nil)
    }

    // MARK: - Seeded initial state

    @Test func configureSeedsIsOnlineFromBackendFetchedProfileOnce() {
        let spy = DriverRepositorySpy()
        let sut = makeSUT(spy: spy)

        sut.configure(initialIsOnline: true)
        #expect(sut.isOnline == true)

        sut.configure(initialIsOnline: false) // second call ignored
        #expect(sut.isOnline == true)
    }
}
