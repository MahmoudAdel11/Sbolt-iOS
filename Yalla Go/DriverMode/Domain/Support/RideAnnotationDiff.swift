//
//  RideAnnotationDiff.swift
//  Yalla Go
//

import Foundation

/// Pure set-diff between the ride IDs currently pinned on the map and the
/// latest polled batch — deliberately framework-free (no MapKit/UIKit) so it
/// is unit-testable on its own. `AvailableRidesMapViewRepresentable`'s
/// coordinator is the only caller; it turns `toAdd`/`toRemove` into actual
/// `MKAnnotation` add/remove calls, never a wipe-and-rebuild, so pins for
/// rides present in both sets are left untouched across a poll tick.
enum RideAnnotationDiff {
    static func compute(existingIDs: Set<String>, incomingIDs: Set<String>) -> (toAdd: Set<String>, toRemove: Set<String>) {
        (incomingIDs.subtracting(existingIDs), existingIDs.subtracting(incomingIDs))
    }
}
