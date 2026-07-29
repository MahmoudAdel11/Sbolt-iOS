//
//  LoginViewModelTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Yalla_Go

@MainActor
struct LoginViewModelTests {

    /// `artificialDelay: 0` keeps the mock deterministic and fast.
    private func makeSUT() -> LoginViewModel {
        let repository = MockAuthenticationRepository(artificialDelay: 0)
        return LoginViewModel(loginUseCase: LoginUseCase(repository: repository))
    }

    @Test func startsInIdleState() {
        let sut = makeSUT()
        #expect(sut.email.isEmpty)
        #expect(sut.password.isEmpty)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
        #expect(sut.loginSucceeded == false)
    }

    @Test func successfulLoginSetsSuccessState() async {
        let sut = makeSUT()
        sut.email = "test@yallago.com"
        sut.password = "password123"

        sut.login()
        await sut.loginTask?.value

        #expect(sut.loginSucceeded)
        #expect(sut.errorMessage == nil)
        #expect(sut.isLoading == false)
    }

    @Test func failedLoginSetsErrorState() async {
        let sut = makeSUT()
        sut.email = "wrong@yallago.com"
        sut.password = "wrongpass"

        sut.login()
        await sut.loginTask?.value

        #expect(sut.loginSucceeded == false)
        #expect(sut.errorMessage == "Incorrect email or password.")
        #expect(sut.isLoading == false)
    }

    @Test func validationFailureShortCircuitsBeforeUseCase() async {
        let sut = makeSUT()
        sut.email = "not-an-email"
        sut.password = "password123"

        sut.login()
        await sut.loginTask?.value

        #expect(sut.errorMessage == "Please enter a valid email address.")
        #expect(sut.loginSucceeded == false)
    }

    @Test func setsLoadingWhileRequestIsInFlight() async {
        let sut = makeSUT()
        sut.email = "test@yallago.com"
        sut.password = "password123"

        sut.login()
        #expect(sut.isLoading == true) // set synchronously before the task runs

        await sut.loginTask?.value
        #expect(sut.isLoading == false)
    }

    @Test func clearsPreviousErrorWhenRetrying() async {
        let sut = makeSUT()
        sut.email = "wrong@yallago.com"
        sut.password = "wrongpass"
        sut.login()
        await sut.loginTask?.value
        #expect(sut.errorMessage != nil)

        sut.email = "test@yallago.com"
        sut.password = "password123"
        sut.login()
        await sut.loginTask?.value

        #expect(sut.errorMessage == nil)
        #expect(sut.loginSucceeded)
    }
}
