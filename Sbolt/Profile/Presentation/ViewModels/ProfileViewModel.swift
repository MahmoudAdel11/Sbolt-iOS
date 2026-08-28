//
//  ProfileViewModel.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation
import Combine

/// Drives the (future) profile screen: loads and updates the profile via use
/// cases and publishes UI-facing state. Main-actor isolated for SwiftUI.
@MainActor
final class ProfileViewModel: ObservableObject {

    @Published private(set) var profile: User?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var updateSucceeded = false
    /// `true` once a `.sessionExpired` error is caught. The view observes
    /// this and signs the session out — the ViewModel itself has no access
    /// to `AppSessionStore` (kept environment-agnostic, testable in isolation).
    @Published private(set) var isSessionExpired = false

    private let getProfileUseCase: GetProfileUseCase
    private let updateProfileUseCase: UpdateProfileUseCase
    private let errorPresenter: ProfileErrorPresenter
    /// Exposed read-only so callers/tests can await the in-flight operation.
    private(set) var activeTask: Task<Void, Never>?

    init(getProfileUseCase: GetProfileUseCase,
         updateProfileUseCase: UpdateProfileUseCase,
         errorPresenter: ProfileErrorPresenter = ProfileErrorPresenter()) {
        self.getProfileUseCase = getProfileUseCase
        self.updateProfileUseCase = updateProfileUseCase
        self.errorPresenter = errorPresenter
    }

    deinit {
        activeTask?.cancel()
    }

    /// Loads the profile. Ignored while another operation is in flight.
    func loadProfile() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        activeTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    /// Saves the edited profile fields. Ignored while another operation is in flight.
    func updateProfile(_ update: ProfileUpdate) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        updateSucceeded = false
        activeTask = Task { [weak self] in
            await self?.performUpdate(update)
        }
    }

    /// Cancels an in-flight operation (e.g. when the screen disappears).
    func cancel() {
        activeTask?.cancel()
    }

    private func performLoad() async {
        defer { isLoading = false }
        do {
            let profile = try await getProfileUseCase.execute()
            guard !Task.isCancelled else { return }
            self.profile = profile
        } catch is CancellationError {
            // Cancelled: leave state untouched.
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = errorPresenter.message(for: error)
            if case ProfileError.sessionExpired = error { isSessionExpired = true }
        }
    }

    private func performUpdate(_ update: ProfileUpdate) async {
        defer { isLoading = false }
        do {
            let profile = try await updateProfileUseCase.execute(update)
            guard !Task.isCancelled else { return }
            self.profile = profile
            updateSucceeded = true
        } catch is CancellationError {
            // Cancelled: leave state untouched.
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = errorPresenter.message(for: error)
            if case ProfileError.sessionExpired = error { isSessionExpired = true }
        }
    }
}
