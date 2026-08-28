//
//  ProfileUpdate.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Editable subset of a user's profile. `id`, `email`, and `createdAt` are
/// intentionally excluded because they are not user-editable here. Grouped into
/// a value type so the repository/use-case signatures stay stable as fields grow.
struct ProfileUpdate: Equatable {
    let username: String
    let phoneNumber: String
    let profileImageURL: URL?
}
