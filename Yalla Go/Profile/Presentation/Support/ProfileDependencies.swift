//
//  ProfileDependencies.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Composition root for the profile feature. Wires the mock repository into the
/// use cases and vends the view model, so views never build use cases or touch
/// the repository directly. Both use cases share one repository instance so an
/// update is visible to a subsequent reload.
struct ProfileDependencies {

    private let repository: ProfileRepository

    init(repository: ProfileRepository = MockProfileRepository()) {
        self.repository = repository
    }

    @MainActor
    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(getProfileUseCase: GetProfileUseCase(repository: repository),
                         updateProfileUseCase: UpdateProfileUseCase(repository: repository))
    }
}
