//
//  UpdateDriverVehicleUseCaseTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Yalla_Go

struct UpdateDriverVehicleUseCaseTests {

    @Test func forwardsAllProvidedFieldsToTheRepository() async throws {
        let repository = MockDriverRepository(artificialDelay: 0)
        let sut = UpdateDriverVehicleUseCase(repository: repository)

        let user = try await sut.execute(
            vehicleType: "Vespa", vehicleColor: "Red", licensePlate: "XYZ-999", scooterType: .premium
        )

        #expect(user.driverProfile?.vehicleType == "Vespa")
        #expect(user.driverProfile?.vehicleColor == "Red")
        #expect(user.driverProfile?.licensePlate == "XYZ-999")
        #expect(user.driverProfile?.scooterType == .premium)
    }

    @Test func onlyTouchesProvidedFieldsLeavingOthersUnchanged() async throws {
        let repository = MockDriverRepository(artificialDelay: 0)
        let sut = UpdateDriverVehicleUseCase(repository: repository)
        _ = try await sut.execute(
            vehicleType: "Vespa", vehicleColor: "Red", licensePlate: "XYZ-999", scooterType: .economy
        )

        let user = try await sut.execute(
            vehicleType: nil, vehicleColor: nil, licensePlate: nil, scooterType: .comfort
        )

        // Only scooterType was provided this time - vehicle fields survive.
        #expect(user.driverProfile?.vehicleType == "Vespa")
        #expect(user.driverProfile?.vehicleColor == "Red")
        #expect(user.driverProfile?.licensePlate == "XYZ-999")
        #expect(user.driverProfile?.scooterType == .comfort)
    }

    @Test func propagatesRepositoryFailure() async {
        let repository = MockDriverRepository(behavior: .networkFailure, artificialDelay: 0)
        let sut = UpdateDriverVehicleUseCase(repository: repository)

        await #expect(throws: DriverError.networkUnavailable) {
            _ = try await sut.execute(
                vehicleType: nil, vehicleColor: nil, licensePlate: nil, scooterType: nil
            )
        }
    }
}
