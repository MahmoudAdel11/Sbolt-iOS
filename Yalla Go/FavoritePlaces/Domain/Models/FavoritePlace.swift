//
//  FavoritePlace.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// A place the user has saved (Home, Work, Gym, …). Contains only what the
/// feature needs — no speculative backend fields.
struct FavoritePlace: Identifiable, Equatable {
    let id: String
    let title: String
    let address: String
    let coordinate: Coordinate
    /// SF Symbol name representing the place.
    let icon: String
    let createdAt: Date
}
