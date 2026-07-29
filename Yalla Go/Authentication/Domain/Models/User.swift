//
//  User.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Authenticated user in the domain layer. Backend-agnostic: it contains only
/// what the app needs today, independent of any API/DTO shape.
struct User: Identifiable, Equatable {
    let id: String
    let username: String
    let email: String
    let phoneNumber: String
    let profileImageURL: URL?
    let createdAt: Date
}
