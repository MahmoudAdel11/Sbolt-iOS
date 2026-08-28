//
//  RegistrationDetails.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Input required to register a new account. Grouped into a domain value type
/// so the repository/use-case signatures stay small and stable as fields grow.
struct RegistrationDetails: Equatable {
    let username: String
    let email: String
    let phoneNumber: String
    let password: String
    let registerAsDriver: Bool
    /// Only meaningful (and required) when `registerAsDriver` is true — a
    /// rider has no scooter to declare. `RegisterUseCase` enforces this
    /// client-side, mirroring (not replacing) the backend's own validator.
    let scooterType: RideType?
}
