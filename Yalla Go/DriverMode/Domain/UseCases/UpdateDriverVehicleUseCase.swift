//
//  UpdateDriverVehicleUseCase.swift
//  Yalla Go
//

import Foundation

/// Partial update of a driver's vehicle/scooter details — only non-nil
/// parameters change, matching the backend's optional-field PATCH semantics.
struct UpdateDriverVehicleUseCase {
    private let repository: DriverRepository

    init(repository: DriverRepository) {
        self.repository = repository
    }

    func execute(
        vehicleType: String?, vehicleColor: String?, licensePlate: String?, scooterType: RideType?
    ) async throws -> User {
        try await repository.updateVehicle(
            vehicleType: vehicleType,
            vehicleColor: vehicleColor,
            licensePlate: licensePlate,
            scooterType: scooterType
        )
    }
}
