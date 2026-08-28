//
//  FavoritePlace.swift
//  Yalla Go
//

import Foundation

/// A place the user has saved (Home, Work, Gym, …). Contains only what the
/// feature needs — no speculative backend fields.
struct FavoritePlace: Identifiable, Equatable {
    let id: String
    let title: String
    let address: String
    let coordinate: Coordinate
    let createdAt: Date

    /// SF Symbol name representing the place — purely client-side, the
    /// backend has no icon/category concept. Derived from `title` by a
    /// simple case-insensitive keyword match:
    ///   contains "home"          → house.fill
    ///   contains "work"/"office" → briefcase.fill
    ///   contains "gym"/"fitness" → dumbbell.fill
    ///   anything else            → mappin.and.ellipse (generic pin)
    /// Never sent to or read from the backend.
    var icon: String {
        let normalized = title.lowercased()
        if normalized.contains("home") {
            return "house.fill"
        } else if normalized.contains("work") || normalized.contains("office") {
            return "briefcase.fill"
        } else if normalized.contains("gym") || normalized.contains("fitness") {
            return "dumbbell.fill"
        } else {
            return "mappin.and.ellipse"
        }
    }
}
