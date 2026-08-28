//
//  TripFormatterTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Sbolt

struct TripFormatterTests {

    private let sut = TripFormatter()
    private let coordinate = Coordinate(latitude: 30.0444, longitude: 31.2357)

    @Test func placeNamePrefersResolvedAddressWhenPresent() {
        let result = sut.placeName("New Cairo", fallback: coordinate)
        #expect(result == "New Cairo")
    }

    /// Matches today's coordinate-only behavior for rides with no resolved
    /// address — older rides predating this feature, or a failed
    /// client-side geocoding lookup at request time.
    @Test func placeNameFallsBackToCoordinateWhenAddressIsNil() {
        let result = sut.placeName(nil, fallback: coordinate)
        #expect(result == sut.coordinate(coordinate))
    }
}
