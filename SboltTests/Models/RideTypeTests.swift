//
//  RideTypeTests.swift
//  Yalla GoTests
//

import Testing
import CoreLocation
@testable import Sbolt

/// Confirms `RideType.computePrice` tracks the backend's real formula
/// (`base_price[tier] + haversine_km(pickup, dropoff) * per_km_rate[tier]`,
/// `app/domain/ride/pricing.py`) closely enough that the pre-request estimate
/// and the real post-request fare no longer diverge by multiples.
struct RideTypeTests {

    // Same pickup/dropoff pair used in the backend's own manual E2E
    // verification for this pricing formula (fare ≈ 21.67 EGP for economy).
    private let pickup = CLLocation(latitude: 30.05, longitude: 31.23)
    private let dropoff = CLLocation(latitude: 30.06, longitude: 31.25)

    /// Independently computed (Python, matching the backend's haversine_km +
    /// compute_fare exactly) expected fare per tier for the coordinates above.
    private let expectedFare: [RideType: Double] = [
        .economy: 21.67,
        .comfort: 35.00,
        .premium: 55.56
    ]

    @Test(arguments: RideType.allCases)
    func computePriceMatchesBackendFormulaWithinASmallTolerance(tier: RideType) {
        let distanceInMeters = pickup.distance(from: dropoff)

        let estimate = tier.computePrice(for: distanceInMeters)

        // A few EGP tolerance covers the negligible geodesic-vs-haversine
        // distance difference between CLLocation and the backend's formula —
        // nowhere near the old ~3x discrepancy this fix corrects.
        let expected = expectedFare[tier]!
        #expect(abs(estimate - expected) < 1.0, "tier \(tier) estimate \(estimate) too far from expected \(expected)")
    }

    @Test func baseFareMatchesBackendBasePricePerTier() {
        #expect(RideType.economy.baseFare == 15)
        #expect(RideType.comfort.baseFare == 25)
        #expect(RideType.premium.baseFare == 40)
    }

    @Test func computePriceIsExactlyBaseFareAtZeroDistance() {
        #expect(RideType.economy.computePrice(for: 0) == 15)
        #expect(RideType.comfort.computePrice(for: 0) == 25)
        #expect(RideType.premium.computePrice(for: 0) == 40)
    }

    @Test func computePriceOrdersTiersConsistentlyForTheSameDistance() {
        let distanceInMeters = pickup.distance(from: dropoff)

        let economy = RideType.economy.computePrice(for: distanceInMeters)
        let comfort = RideType.comfort.computePrice(for: distanceInMeters)
        let premium = RideType.premium.computePrice(for: distanceInMeters)

        #expect(economy < comfort)
        #expect(comfort < premium)
    }
}
