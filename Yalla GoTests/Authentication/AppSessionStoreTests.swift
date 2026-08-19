//
//  AppSessionStoreTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Yalla_Go

@MainActor
struct AppSessionStoreTests {

    private func makeUser(driverProfile: DriverProfile?) -> User {
        User(id: "1", username: "Sam", email: "sam@x.com", phoneNumber: "+2011",
             profileImageURL: nil, createdAt: Date(), driverProfile: driverProfile)
    }

    @Test func switchToDriverIsNoOpWithoutDriverProfile() {
        let sut = AppSessionStore()
        sut.signIn(user: makeUser(driverProfile: nil))

        sut.switchMode(to: .driver)

        #expect(sut.currentMode == .customer)
    }

    @Test func switchToDriverSucceedsWithDriverProfile() {
        let sut = AppSessionStore()
        sut.signIn(user: makeUser(driverProfile: DriverProfile(isOnline: false)))

        sut.switchMode(to: .driver)

        #expect(sut.currentMode == .driver)
    }

    @Test func switchBackToCustomerAlwaysSucceeds() {
        let sut = AppSessionStore()
        sut.signIn(user: makeUser(driverProfile: DriverProfile(isOnline: false)))
        sut.switchMode(to: .driver)

        sut.switchMode(to: .customer)

        #expect(sut.currentMode == .customer)
    }

    @Test func signInResetsModeToCustomer() {
        let sut = AppSessionStore()
        sut.signIn(user: makeUser(driverProfile: DriverProfile(isOnline: false)))
        sut.switchMode(to: .driver)

        sut.signIn(user: makeUser(driverProfile: DriverProfile(isOnline: false)))

        #expect(sut.currentMode == .customer)
    }

    @Test func signOutResetsModeToCustomer() {
        let sut = AppSessionStore()
        sut.signIn(user: makeUser(driverProfile: DriverProfile(isOnline: false)))
        sut.switchMode(to: .driver)

        sut.signOut()

        #expect(sut.currentMode == .customer)
    }
}
