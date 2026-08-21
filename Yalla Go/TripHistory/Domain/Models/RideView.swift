//
//  RideView.swift
//  Yalla Go
//

import Foundation

/// Which side of a ride history is being requested. Mirrors the backend's
/// `as` query param on `GET /rides/history` (`rider`|`driver`, default
/// `rider`) exactly — raw values match the wire strings.
enum RideView: String {
    case rider
    case driver
}
