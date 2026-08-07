//
//  TripFormatter.swift
//  Yalla Go
//

import Foundation

/// Formats trip values for display. Kept in one place so the card and the
/// details screen present dates and coordinates identically. Distance,
/// duration, price, and location-name formatting were removed — the backend
/// supplies none of those fields.
struct TripFormatter {

    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
    }

    func date(_ value: Date) -> String {
        dateFormatter.string(from: value)
    }

    func time(_ value: Date) -> String {
        timeFormatter.string(from: value)
    }

    /// e.g. "30.0444, 31.2357" — the backend has no address/location-name
    /// field, only coordinates.
    func coordinate(_ value: Coordinate) -> String {
        String(format: "%.4f, %.4f", value.latitude, value.longitude)
    }
}
