//
//  AutoZoomTrigger.swift
//  Yalla Go
//

import Foundation

/// Pure decision for whether the driver map's camera should auto-fit to
/// the driver + available rides — deliberately framework-free (no MapKit)
/// so it is unit-testable on its own, mirroring `RideAnnotationDiff`.
///
/// Fires whenever the latest poll batch contains at least one ride ID that
/// hasn't been accounted for in a previous auto-zoom — not just on the
/// first empty→non-empty transition of the online session. That narrower
/// rule (fire at most once, ever, per session) failed two real cases: a
/// second ride arriving shortly after the first never got included in the
/// frame, and a fresh ride arriving after an earlier one was
/// cancelled/removed never re-triggered a zoom at all, since the visible
/// count never actually returned to zero (or `hasZoomedThisSession` was
/// already `true` regardless). Tracking *which ride IDs have already been
/// zoomed for*, rather than a one-shot flag or a raw count, fixes both:
/// re-fetching the same rides on a background poll tick never re-fires
/// (every ID is already accounted for), but any genuinely new ride does.
///
/// `AvailableRidesMapViewRepresentable`'s coordinator owns the
/// `zoomedRideIDs` set this reads — and since the map view (and its
/// coordinator) is torn down and rebuilt every time the driver goes offline
/// and back online, or accepts then completes a ride (`DriverHomeView` only
/// shows the map while online with no active ride), that set resets to
/// empty for free on a new session with no extra plumbing.
enum AutoZoomTrigger {
    static func shouldZoom(zoomedRideIDs: Set<String>, incomingIDs: Set<String>) -> Bool {
        !incomingIDs.isEmpty && !incomingIDs.isSubset(of: zoomedRideIDs)
    }
}
