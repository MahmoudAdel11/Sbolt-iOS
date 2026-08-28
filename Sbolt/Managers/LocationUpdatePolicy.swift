//
//  LocationUpdatePolicy.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import CoreLocation

/// Pure decision logic that decides whether a freshly reported location
/// should replace the currently accepted one. Kept free of CoreLocation
/// side effects so it can be unit tested in isolation.
struct LocationUpdatePolicy {

    /// Minimum horizontal movement (in meters) required to accept a new fix.
    /// Also filters out duplicate / meaningless updates.
    var minimumDistance: CLLocationDistance = 10

    /// Maximum age (in seconds) for a fix to still be considered fresh.
    var maximumAge: TimeInterval = 5

    /// - Returns: `true` when `candidate` is a valid, fresh, forward-moving fix
    ///   that differs meaningfully from `current`.
    func shouldAccept(_ candidate: CLLocation,
                      over current: CLLocation?,
                      now: Date = Date()) -> Bool {
        // Reject invalid coordinates or invalid (negative) accuracy.
        guard CLLocationCoordinate2DIsValid(candidate.coordinate),
              candidate.horizontalAccuracy >= 0 else { return false }

        // Reject stale fixes.
        guard now.timeIntervalSince(candidate.timestamp) <= maximumAge else { return false }

        // First valid fix is always accepted.
        guard let current else { return true }

        // Reject out-of-order (older) fixes so a newer one is never overwritten.
        guard candidate.timestamp > current.timestamp else { return false }

        // Ignore tiny, meaningless movements (and exact duplicates).
        return candidate.distance(from: current) >= minimumDistance
    }
}
