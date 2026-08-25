//
//  RideType.swift
//  Yalla Go
//
//  Created by Mahmoud on 15/03/2025.
//

import Foundation

/// A ride tier. `rawValue` is the exact backend wire string
/// ("economy"/"comfort"/"premium") — used directly in `RideDTO.RideRequest`/
/// decoded directly from `RideDTO.RideResponse`, with no second string
/// representation to keep in sync.
///
/// Case-to-backend-tier mapping was derived from relative pricing, not
/// guessed: the old client-side base fares ordered uberX(5) < uberXL(10) <
/// black(20), which lines up exactly with the backend's
/// economy(15) < comfort(25) < premium(40) — so uberX -> economy,
/// uberXL -> comfort, black -> premium.
enum RideType: String, CaseIterable, Identifiable {
    case economy
    case comfort
    case premium

    var id: String { rawValue }

    var description: String {
        switch self {
        case .economy: return "YallaX"
        case .comfort: return "YallaComfort"
        case .premium: return "YallaBlack"
        }
    }

    var imageName: String {
        switch self {
        case .economy, .comfort: return "yallaGoXIcon"
        case .premium: return "yallaGo-black"
        }
    }

    /// Client-side-only pre-request estimate, shown before `POST /rides` is
    /// ever sent (the real, authoritative fare comes back on `Trip.fare`
    /// once the ride actually exists — this is never sent to the backend
    /// and never treated as final).
    var baseFare: Double {
        switch self {
        case .economy: return 5
        case .comfort: return 10
        case .premium: return 20
        }
    }

    func computePrice(for distanceInMeters: Double) -> Double {
        let distanceInMiles = distanceInMeters / 1600
        switch self {
        case .economy: return distanceInMiles * 1.5 + baseFare
        case .comfort: return distanceInMiles * 1.75 + baseFare
        case .premium: return distanceInMiles * 2.0 + baseFare
        }
    }
}
