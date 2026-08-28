//
//  ProfileUseCaseTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Sbolt

struct ProfileUseCaseTests {

    private let update = ProfileUpdate(username: "New Name",
                                       phoneNumber: "+201234567890",
                                       profileImageURL: nil)

    // MARK: - GetProfileUseCase

    @Test func getProfileReturnsProfileOnSuccess() async throws {
        let repository = MockProfileRepository(artificialDelay: 0)
        let sut = GetProfileUseCase(repository: repository)

        let profile = try await sut.execute()

        #expect(profile.username == "Test User")
    }

    @Test func getProfilePropagatesFailure() async {
        let repository = MockProfileRepository(behavior: .failure, artificialDelay: 0)
        let sut = GetProfileUseCase(repository: repository)

        await #expect(throws: ProfileError.profileUnavailable) {
            _ = try await sut.execute()
        }
    }

    // MARK: - UpdateProfileUseCase

    @Test func updateProfileReturnsUpdatedProfileOnSuccess() async throws {
        let repository = MockProfileRepository(artificialDelay: 0)
        let sut = UpdateProfileUseCase(repository: repository)

        let updated = try await sut.execute(update)

        #expect(updated.username == "New Name")
        #expect(updated.phoneNumber == "+201234567890")
    }

    @Test func updateProfilePropagatesFailure() async {
        let repository = MockProfileRepository(behavior: .failure, artificialDelay: 0)
        let sut = UpdateProfileUseCase(repository: repository)

        await #expect(throws: ProfileError.updateFailed) {
            _ = try await sut.execute(update)
        }
    }
}
