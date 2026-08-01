//
//  Driver.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation

/// A matched driver for a trip. Mock values only — no networking.
struct Driver: Identifiable, Equatable {
    let id: String
    let name: String
    let rating: Double
    let vehicleName: String
    let vehicleColor: String
    let plateNumber: String
    /// SF Symbol name used as the mock profile image.
    let profileImage: String
    /// Estimated arrival to the pickup point, in minutes.
    let estimatedArrivalMinutes: Int
}
