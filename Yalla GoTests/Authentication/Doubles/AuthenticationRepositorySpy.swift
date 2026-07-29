//
//  AuthenticationRepositorySpy.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation
@testable import Yalla_Go

/// Records interactions and returns canned results so use cases can be tested
/// in isolation from the concrete mock repository.
actor AuthenticationRepositorySpy: AuthenticationRepository {

    private(set) var loginCallCount = 0
    private(set) var lastLoginEmail: String?
    private(set) var lastLoginPassword: String?
    private(set) var registerCallCount = 0
    private(set) var lastRegistration: RegistrationDetails?
    private(set) var logoutCallCount = 0

    private let loginResult: Result<User, Error>
    private let registerResult: Result<User, Error>
    private let stubbedCurrentUser: User?

    init(loginResult: Result<User, Error> = .success(.stub),
         registerResult: Result<User, Error> = .success(.stub),
         stubbedCurrentUser: User? = nil) {
        self.loginResult = loginResult
        self.registerResult = registerResult
        self.stubbedCurrentUser = stubbedCurrentUser
    }

    func login(email: String, password: String) async throws -> User {
        loginCallCount += 1
        lastLoginEmail = email
        lastLoginPassword = password
        return try loginResult.get()
    }

    func register(_ details: RegistrationDetails) async throws -> User {
        registerCallCount += 1
        lastRegistration = details
        return try registerResult.get()
    }

    func logout() async throws {
        logoutCallCount += 1
    }

    func currentUser() async -> User? {
        stubbedCurrentUser
    }

    func isAuthenticated() async -> Bool {
        stubbedCurrentUser != nil
    }
}

extension User {
    /// Deterministic user for assertions in tests.
    static var stub: User {
        User(id: "stub-id",
             username: "Stub",
             email: "stub@yallago.com",
             phoneNumber: "+200000000000",
             profileImageURL: nil,
             createdAt: Date(timeIntervalSince1970: 0))
    }
}
