//
//  MockProfileRepositoryTests.swift
//  Yalla GoTests
//
//  Created by Mahmoud on 29/07/2026.
//

import Testing
import Foundation
@testable import Yalla_Go

struct MockProfileRepositoryTests {

    private let update = ProfileUpdate(username: "New Name",
                                       phoneNumber: "+201234567890",
                                       profileImageURL: URL(string: "https://example.com/a.png"))

    @Test func loadProfileSucceeds() async throws {
        let sut = MockProfileRepository(artificialDelay: 0)
        let profile = try await sut.getProfile()
        #expect(profile.username == "Test User")
        #expect(profile.email == "test@yallago.com")
    }

    @Test func loadProfileFails() async {
        let sut = MockProfileRepository(behavior: .failure, artificialDelay: 0)
        await #expect(throws: ProfileError.profileUnavailable) {
            _ = try await sut.getProfile()
        }
    }

    @Test func updateProfileSucceedsAndPersists() async throws {
        let sut = MockProfileRepository(artificialDelay: 0)

        let updated = try await sut.updateProfile(update)
        #expect(updated.username == "New Name")
        #expect(updated.phoneNumber == "+201234567890")

        // Change is persisted for subsequent reads, email/id unchanged.
        let reloaded = try await sut.getProfile()
        #expect(reloaded.username == "New Name")
        #expect(reloaded.email == "test@yallago.com")
    }

    @Test func updateProfileFails() async {
        let sut = MockProfileRepository(behavior: .failure, artificialDelay: 0)
        await #expect(throws: ProfileError.updateFailed) {
            _ = try await sut.updateProfile(update)
        }
    }
}
