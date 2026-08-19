//
//  MockAuthenticationRepositoryTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Yalla_Go

struct MockAuthenticationRepositoryTests {

    private func makeSUT() -> MockAuthenticationRepository {
        // Zero delay keeps tests fast and deterministic.
        MockAuthenticationRepository(artificialDelay: 0)
    }

    @Test func startsSignedOut() async {
        let sut = makeSUT()
        #expect(await sut.currentUser() == nil)
        #expect(await sut.isAuthenticated() == false)
    }

    @Test func loginSucceedsWithValidCredentials() async throws {
        let sut = makeSUT()
        let user = try await sut.login(email: "test@yallago.com", password: "password123")
        #expect(user.email == "test@yallago.com")
        #expect(await sut.isAuthenticated())
        #expect(await sut.currentUser() == user)
    }

    @Test func loginFailsWithInvalidCredentials() async {
        let sut = makeSUT()
        await #expect(throws: AuthenticationError.invalidCredentials) {
            _ = try await sut.login(email: "wrong@yallago.com", password: "nope")
        }
        #expect(await sut.isAuthenticated() == false)
    }

    @Test func registerSucceedsWithNewEmail() async throws {
        let sut = makeSUT()
        let details = RegistrationDetails(username: "Sara",
                                          email: "sara@yallago.com",
                                          phoneNumber: "+201111111111",
                                          password: "secret123",
                                          registerAsDriver: false)
        let user = try await sut.register(details)
        #expect(user.email == "sara@yallago.com")
        #expect(user.username == "Sara")
        #expect(await sut.isAuthenticated())
    }

    @Test func registerFailsWhenEmailAlreadyExists() async {
        let sut = makeSUT()
        let details = RegistrationDetails(username: "Test",
                                          email: "test@yallago.com", // seeded
                                          phoneNumber: "+201000000000",
                                          password: "password123",
                                          registerAsDriver: false)
        await #expect(throws: AuthenticationError.emailAlreadyExists) {
            _ = try await sut.register(details)
        }
    }

    @Test func logoutClearsSession() async throws {
        let sut = makeSUT()
        _ = try await sut.login(email: "test@yallago.com", password: "password123")
        try await sut.logout()
        #expect(await sut.currentUser() == nil)
        #expect(await sut.isAuthenticated() == false)
    }
}
