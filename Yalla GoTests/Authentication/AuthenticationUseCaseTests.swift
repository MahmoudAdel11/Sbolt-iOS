//
//  AuthenticationUseCaseTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Yalla_Go

struct AuthenticationUseCaseTests {

    // MARK: - LoginUseCase

    @Test func loginForwardsTrimmedCredentialsAndReturnsUser() async throws {
        let spy = AuthenticationRepositorySpy(loginResult: .success(.stub))
        let sut = LoginUseCase(repository: spy)

        let user = try await sut.execute(email: "  a@b.com ", password: "secret")

        #expect(user == .stub)
        #expect(await spy.loginCallCount == 1)
        #expect(await spy.lastLoginEmail == "a@b.com")
        #expect(await spy.lastLoginPassword == "secret")
    }

    @Test func loginRejectsEmptyInputWithoutCallingRepository() async {
        let spy = AuthenticationRepositorySpy()
        let sut = LoginUseCase(repository: spy)

        await #expect(throws: AuthenticationError.invalidCredentials) {
            _ = try await sut.execute(email: "   ", password: "")
        }
        #expect(await spy.loginCallCount == 0)
    }

    @Test func loginPropagatesRepositoryError() async {
        let spy = AuthenticationRepositorySpy(loginResult: .failure(AuthenticationError.invalidCredentials))
        let sut = LoginUseCase(repository: spy)

        await #expect(throws: AuthenticationError.invalidCredentials) {
            _ = try await sut.execute(email: "a@b.com", password: "secret")
        }
    }

    // MARK: - RegisterUseCase

    @Test func registerForwardsSanitizedDetails() async throws {
        let spy = AuthenticationRepositorySpy(registerResult: .success(.stub))
        let sut = RegisterUseCase(repository: spy)
        let details = RegistrationDetails(username: " Sam ",
                                          email: " sam@x.com ",
                                          phoneNumber: " +2011 ",
                                          password: "secret",
                                          registerAsDriver: false,
                                          scooterType: nil)

        _ = try await sut.execute(details)

        #expect(await spy.registerCallCount == 1)
        #expect(await spy.lastRegistration?.username == "Sam")
        #expect(await spy.lastRegistration?.email == "sam@x.com")
        #expect(await spy.lastRegistration?.phoneNumber == "+2011")
        #expect(await spy.lastRegistration?.registerAsDriver == false)
    }

    @Test func registerForwardsRegisterAsDriverFlagWhenTrue() async throws {
        let spy = AuthenticationRepositorySpy(registerResult: .success(.stub))
        let sut = RegisterUseCase(repository: spy)
        let details = RegistrationDetails(username: "Sam",
                                          email: "sam@x.com",
                                          phoneNumber: "+2011",
                                          password: "secret",
                                          registerAsDriver: true,
                                          scooterType: .comfort)

        _ = try await sut.execute(details)

        #expect(await spy.lastRegistration?.registerAsDriver == true)
    }

    @Test func registerRejectsInvalidInput() async {
        let spy = AuthenticationRepositorySpy()
        let sut = RegisterUseCase(repository: spy)
        let details = RegistrationDetails(username: "",
                                          email: "not-an-email",
                                          phoneNumber: "",
                                          password: "123",
                                          registerAsDriver: false,
                                          scooterType: nil)

        await #expect(throws: AuthenticationError.invalidInput) {
            _ = try await sut.execute(details)
        }
        #expect(await spy.registerCallCount == 0)
    }

    @Test func registerPropagatesRepositoryError() async {
        let spy = AuthenticationRepositorySpy(registerResult: .failure(AuthenticationError.emailAlreadyExists))
        let sut = RegisterUseCase(repository: spy)
        let details = RegistrationDetails(username: "Sam",
                                          email: "sam@x.com",
                                          phoneNumber: "+2011",
                                          password: "secret",
                                          registerAsDriver: false,
                                          scooterType: nil)

        await #expect(throws: AuthenticationError.emailAlreadyExists) {
            _ = try await sut.execute(details)
        }
    }

    // MARK: - RegisterUseCase — scooterType validation

    @Test func registerRejectsDriverRegistrationWithoutScooterType() async {
        let spy = AuthenticationRepositorySpy()
        let sut = RegisterUseCase(repository: spy)
        let details = RegistrationDetails(username: "Sam",
                                          email: "sam@x.com",
                                          phoneNumber: "+2011",
                                          password: "secret",
                                          registerAsDriver: true,
                                          scooterType: nil)

        await #expect(throws: AuthenticationError.invalidInput) {
            _ = try await sut.execute(details)
        }
        #expect(await spy.registerCallCount == 0)
    }

    @Test func registerAllowsRiderRegistrationWithoutScooterType() async throws {
        let spy = AuthenticationRepositorySpy(registerResult: .success(.stub))
        let sut = RegisterUseCase(repository: spy)
        let details = RegistrationDetails(username: "Sam",
                                          email: "sam@x.com",
                                          phoneNumber: "+2011",
                                          password: "secret",
                                          registerAsDriver: false,
                                          scooterType: nil)

        _ = try await sut.execute(details)

        #expect(await spy.registerCallCount == 1)
    }

    @Test func registerAllowsDriverRegistrationWithScooterType() async throws {
        let spy = AuthenticationRepositorySpy(registerResult: .success(.stub))
        let sut = RegisterUseCase(repository: spy)
        let details = RegistrationDetails(username: "Sam",
                                          email: "sam@x.com",
                                          phoneNumber: "+2011",
                                          password: "secret",
                                          registerAsDriver: true,
                                          scooterType: .premium)

        _ = try await sut.execute(details)

        #expect(await spy.registerCallCount == 1)
        #expect(await spy.lastRegistration?.scooterType == .premium)
    }

    // MARK: - LogoutUseCase

    @Test func logoutCallsRepository() async throws {
        let spy = AuthenticationRepositorySpy()
        let sut = LogoutUseCase(repository: spy)

        try await sut.execute()

        #expect(await spy.logoutCallCount == 1)
    }

    // MARK: - GetCurrentUserUseCase

    @Test func getCurrentUserReturnsRepositoryUser() async {
        let spy = AuthenticationRepositorySpy(stubbedCurrentUser: .stub)
        let sut = GetCurrentUserUseCase(repository: spy)

        #expect(await sut.execute() == .stub)
    }

    @Test func getCurrentUserReturnsNilWhenSignedOut() async {
        let spy = AuthenticationRepositorySpy(stubbedCurrentUser: nil)
        let sut = GetCurrentUserUseCase(repository: spy)

        #expect(await sut.execute() == nil)
    }
}
