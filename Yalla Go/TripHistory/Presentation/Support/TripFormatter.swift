//
//  TripFormatter.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Formats trip values for display. Kept in one place so the card and the
/// details screen present distance, duration, and dates identically.
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

    /// Distance in kilometres, e.g. "14.2 km".
    func distance(meters: Double) -> String {
        String(format: "%.1f km", meters / 1000)
    }

    /// Duration in whole minutes, e.g. "24 min".
    func duration(seconds: TimeInterval) -> String {
        let minutes = Int((seconds / 60).rounded())
        return "\(minutes) min"
    }

    func price(_ value: Double) -> String {
        value.toCurrency()
    }
}
