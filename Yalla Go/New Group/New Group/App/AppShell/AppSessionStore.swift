//
//  AppSessionStore.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation
import Combine

/// Centralised, mock authentication state for the app shell. Isolated here so
/// the real authentication flow can later drive `isAuthenticated` without
/// changing any screen. This is the single source of truth for "is the user
/// signed in", intentionally not a singleton — it's injected from the app entry.
@MainActor
final class AppSessionStore: ObservableObject {
    @Published var isAuthenticated: Bool

    init(isAuthenticated: Bool = true) {
        self.isAuthenticated = isAuthenticated
    }
}
