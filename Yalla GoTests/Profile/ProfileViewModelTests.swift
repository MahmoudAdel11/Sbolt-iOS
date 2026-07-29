//
//  ProfileViewModelTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Yalla_Go

@MainActor
struct ProfileViewModelTests {

    private let update = ProfileUpdate(username: "New Name",
                                       phoneNumber: "+201234567890",
                                       profileImageURL: nil)

    private func makeSUT(behavior: MockProfileRepository.Behavior = .success) -> ProfileViewModel {
        let repository = MockProfileRepository(behavior: behavior, artificialDelay: 0)
        return ProfileViewModel(getProfileUseCase: GetProfileUseCase(repository: repository),
                                updateProfileUseCase: UpdateProfileUseCase(repository: repository))
    }

    @Test func startsInIdleState() {
        let sut = makeSUT()
        #expect(sut.profile == nil)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
        #expect(sut.updateSucceeded == false)
    }

    @Test func loadProfileSuccessPublishesProfile() async {
        let sut = makeSUT()

        sut.loadProfile()
        await sut.activeTask?.value

        #expect(sut.profile?.username == "Test User")
        #expect(sut.errorMessage == nil)
        #expect(sut.isLoading == false)
    }

    @Test func loadProfileFailurePublishesError() async {
        let sut = makeSUT(behavior: .failure)

        sut.loadProfile()
        await sut.activeTask?.value

        #expect(sut.profile == nil)
        #expect(sut.errorMessage == "We couldn't load your profile. Please try again.")
        #expect(sut.isLoading == false)
    }

    @Test func setsLoadingWhileRequestIsInFlight() async {
        let sut = makeSUT()

        sut.loadProfile()
        #expect(sut.isLoading == true) // set synchronously before the task runs

        await sut.activeTask?.value
        #expect(sut.isLoading == false)
    }

    @Test func updateProfileSuccessSetsSuccessState() async {
        let sut = makeSUT()

        sut.updateProfile(update)
        await sut.activeTask?.value

        #expect(sut.updateSucceeded)
        #expect(sut.profile?.username == "New Name")
        #expect(sut.errorMessage == nil)
    }

    @Test func updateProfileFailurePublishesError() async {
        let sut = makeSUT(behavior: .failure)

        sut.updateProfile(update)
        await sut.activeTask?.value

        #expect(sut.updateSucceeded == false)
        #expect(sut.errorMessage == "We couldn't save your changes. Please try again.")
    }
}
