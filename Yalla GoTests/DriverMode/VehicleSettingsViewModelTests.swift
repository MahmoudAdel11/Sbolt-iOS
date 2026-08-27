//
//  VehicleSettingsViewModelTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Yalla_Go

@MainActor
struct VehicleSettingsViewModelTests {

    private func makeSUT(spy: DriverRepositorySpy) -> VehicleSettingsViewModel {
        VehicleSettingsViewModel(updateDriverVehicleUseCase: UpdateDriverVehicleUseCase(repository: spy))
    }

    @Test func updateVehicleSuccessPublishesUpdatedUserAndSucceededFlag() async {
        let spy = DriverRepositorySpy(updateVehicleResult: .success(.driverStub))
        let sut = makeSUT(spy: spy)

        sut.updateVehicle(vehicleType: "Vespa", vehicleColor: "Red", licensePlate: nil, scooterType: .premium)
        await sut.activeTask?.value

        #expect(sut.updateSucceeded == true)
        #expect(sut.updatedUser == .driverStub)
        #expect(sut.errorMessage == nil)
    }

    @Test func updateVehicleForwardsExactArgumentsToTheUseCase() async {
        let spy = DriverRepositorySpy(updateVehicleResult: .success(.driverStub))
        let sut = makeSUT(spy: spy)

        sut.updateVehicle(vehicleType: nil, vehicleColor: "Black", licensePlate: nil, scooterType: nil)
        await sut.activeTask?.value

        let args = await spy.lastUpdateVehicleArgs
        #expect(args?.vehicleType == nil)
        #expect(args?.vehicleColor == "Black")
        #expect(args?.licensePlate == nil)
        #expect(args?.scooterType == nil)
    }

    @Test func updateVehicleFailurePublishesErrorMessage() async {
        let spy = DriverRepositorySpy(updateVehicleResult: .failure(DriverError.networkUnavailable))
        let sut = makeSUT(spy: spy)

        sut.updateVehicle(vehicleType: nil, vehicleColor: nil, licensePlate: nil, scooterType: nil)
        await sut.activeTask?.value

        #expect(sut.errorMessage == "No internet connection. Please try again.")
        #expect(sut.updateSucceeded == false)
    }

    @Test func sessionExpiredOnUpdateSetsFlag() async {
        let spy = DriverRepositorySpy(updateVehicleResult: .failure(DriverError.sessionExpired))
        let sut = makeSUT(spy: spy)

        sut.updateVehicle(vehicleType: nil, vehicleColor: nil, licensePlate: nil, scooterType: nil)
        await sut.activeTask?.value

        #expect(sut.isSessionExpired == true)
    }
}
