//
//  VehicleSettingsViewModel.swift
//  Yalla Go
//

import Foundation
import Combine

/// Drives the vehicle/scooter-type settings screen: saves a partial update
/// via `UpdateDriverVehicleUseCase` and publishes UI-facing state. Mirrors
/// `ProfileViewModel`'s load/save shape. Main-actor isolated for SwiftUI.
@MainActor
final class VehicleSettingsViewModel: ObservableObject {

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var updateSucceeded = false
    /// The refreshed user after a successful save — the view forwards this
    /// to `AppSessionStore` so the rest of the app sees the change immediately.
    @Published private(set) var updatedUser: User?
    /// `true` once a `.sessionExpired` error is caught. The view observes
    /// this and signs the session out — the ViewModel itself has no access
    /// to `AppSessionStore` (kept environment-agnostic, testable in isolation).
    @Published private(set) var isSessionExpired = false

    private let updateDriverVehicleUseCase: UpdateDriverVehicleUseCase
    private let errorPresenter: DriverErrorPresenter
    /// Exposed read-only so callers/tests can await the in-flight operation.
    private(set) var activeTask: Task<Void, Never>?

    init(updateDriverVehicleUseCase: UpdateDriverVehicleUseCase,
         errorPresenter: DriverErrorPresenter = DriverErrorPresenter()) {
        self.updateDriverVehicleUseCase = updateDriverVehicleUseCase
        self.errorPresenter = errorPresenter
    }

    deinit {
        activeTask?.cancel()
    }

    /// Saves a partial update. Ignored while another operation is in flight.
    func updateVehicle(
        vehicleType: String?, vehicleColor: String?, licensePlate: String?, scooterType: RideType?
    ) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        updateSucceeded = false
        activeTask = Task { [weak self] in
            await self?.performUpdate(
                vehicleType: vehicleType, vehicleColor: vehicleColor,
                licensePlate: licensePlate, scooterType: scooterType
            )
        }
    }

    /// Cancels an in-flight operation (e.g. when the screen disappears).
    func cancel() {
        activeTask?.cancel()
    }

    private func performUpdate(
        vehicleType: String?, vehicleColor: String?, licensePlate: String?, scooterType: RideType?
    ) async {
        defer { isLoading = false }
        do {
            let user = try await updateDriverVehicleUseCase.execute(
                vehicleType: vehicleType, vehicleColor: vehicleColor,
                licensePlate: licensePlate, scooterType: scooterType
            )
            guard !Task.isCancelled else { return }
            updatedUser = user
            updateSucceeded = true
        } catch is CancellationError {
            // Cancelled: leave state untouched.
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = errorPresenter.message(for: error)
            if case DriverError.sessionExpired = error { isSessionExpired = true }
        }
    }
}
