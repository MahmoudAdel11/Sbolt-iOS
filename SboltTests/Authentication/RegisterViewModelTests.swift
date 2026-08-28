//
//  RegisterViewModelTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Sbolt

@MainActor
struct RegisterViewModelTests {

    private func makeSUT() -> RegisterViewModel {
        let repository = MockAuthenticationRepository(artificialDelay: 0)
        return RegisterViewModel(registerUseCase: RegisterUseCase(repository: repository))
    }

    private func fillValidForm(_ sut: RegisterViewModel,
                               email: String = "sara@yallago.com") {
        sut.username = "Sara"
        sut.email = email
        sut.phoneNumber = "+201111111111"
        sut.password = "secret123"
        sut.confirmPassword = "secret123"
    }

    @Test func startsInIdleState() {
        let sut = makeSUT()
        #expect(sut.username.isEmpty)
        #expect(sut.email.isEmpty)
        #expect(sut.phoneNumber.isEmpty)
        #expect(sut.password.isEmpty)
        #expect(sut.confirmPassword.isEmpty)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
        #expect(sut.registrationSucceeded == false)
    }

    @Test func successfulRegistrationSetsSuccessState() async {
        let sut = makeSUT()
        fillValidForm(sut)

        sut.register()
        await sut.registerTask?.value

        #expect(sut.registrationSucceeded)
        #expect(sut.errorMessage == nil)
        #expect(sut.isLoading == false)
    }

    @Test func failedRegistrationSetsErrorState() async {
        let sut = makeSUT()
        // Seeded email already exists in the mock backend.
        fillValidForm(sut, email: "test@yallago.com")

        sut.register()
        await sut.registerTask?.value

        #expect(sut.registrationSucceeded == false)
        #expect(sut.errorMessage == "An account with this email already exists.")
    }

    @Test func invalidEmailFailsValidation() async {
        let sut = makeSUT()
        fillValidForm(sut, email: "invalid-email")

        sut.register()
        await sut.registerTask?.value

        #expect(sut.errorMessage == "Please enter a valid email address.")
        #expect(sut.registrationSucceeded == false)
    }

    @Test func passwordMismatchFailsValidation() async {
        let sut = makeSUT()
        fillValidForm(sut)
        sut.confirmPassword = "different"

        sut.register()
        await sut.registerTask?.value

        #expect(sut.errorMessage == "Passwords do not match.")
        #expect(sut.registrationSucceeded == false)
    }

    @Test func missingUsernameFailsValidation() async {
        let sut = makeSUT()
        fillValidForm(sut)
        sut.username = "   "

        sut.register()
        await sut.registerTask?.value

        #expect(sut.errorMessage == "Please enter your username.")
        #expect(sut.registrationSucceeded == false)
    }

    @Test func setsLoadingWhileRequestIsInFlight() async {
        let sut = makeSUT()
        fillValidForm(sut)

        sut.register()
        #expect(sut.isLoading == true) // set synchronously before the task runs

        await sut.registerTask?.value
        #expect(sut.isLoading == false)
    }
}
