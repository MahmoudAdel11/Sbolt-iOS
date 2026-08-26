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
        case .economy: return "Street"
        case .comfort: return "Ride"
        case .premium: return "Black"
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
    ///
    /// MAINTENANCE: these EGP values MUST be kept in sync by hand with the
    /// backend's `_BASE_PRICE_EGP` in `app/domain/ride/pricing.py` — there is
    /// no shared source of truth between the two codebases. If the backend's
    /// pricing constants ever change, this estimate silently drifts out of
    /// sync again until someone updates it here too; this fix makes the two
    /// match today, it doesn't structurally prevent future divergence.
    var baseFare: Double {
        switch self {
        case .economy: return 15
        case .comfort: return 25
        case .premium: return 40
        }
    }

    /// Per-km rate in EGP — same manual-sync caveat as `baseFare`, mirrors
    /// the backend's `_PER_KM_RATE_EGP`.
    private var perKilometerRateEGP: Double {
        switch self {
        case .economy: return 3.0
        case .comfort: return 4.5
        case .premium: return 7.0
        }
    }

    /// Mirrors the backend's `compute_fare` exactly: `base_price[tier] +
    /// distance_km * per_km_rate[tier]`. Distance measurement matches too —
    /// the backend uses `haversine_km` (straight-line, great-circle)
    /// specifically because that's what this call site already used
    /// (`CLLocation.distance(from:)`, also straight-line); the two agree to
    /// well under 1% for any realistic trip, so this doesn't introduce a
    /// second discrepancy on top of fixing the pricing constants.
    func computePrice(for distanceInMeters: Double) -> Double {
        let distanceInKilometers = distanceInMeters / 1000
        return baseFare + distanceInKilometers * perKilometerRateEGP
    }
}
