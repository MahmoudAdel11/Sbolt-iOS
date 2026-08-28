//
//  ReverseGeocodingTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Sbolt

/// In-memory stand-in for `CLGeocoderReverseGeocoding` — exercises callers
/// (the view model) without hitting Apple's networked geocoding service.
final class StubReverseGeocoding: ReverseGeocoding {
    enum Behavior {
        case success(String)
        case failure
    }

    private let behavior: Behavior
    private(set) var requestedCoordinates: [Coordinate] = []

    init(behavior: Behavior = .success("New Cairo")) {
        self.behavior = behavior
    }

    func placeName(for coordinate: Coordinate) async -> String? {
        requestedCoordinates.append(coordinate)
        switch behavior {
        case .success(let name): return name
        case .failure: return nil
        }
    }
}

struct ReverseGeocodingTests {

    @Test func stubReturnsConfiguredNameOnSuccess() async {
        let sut = StubReverseGeocoding(behavior: .success("Downtown Cairo"))
        let name = await sut.placeName(for: Coordinate(latitude: 30.05, longitude: 31.23))
        #expect(name == "Downtown Cairo")
    }

    /// Mirrors the product decision that a resolution failure (offline, no
    /// result, timeout) must never throw — `ReverseGeocoding.placeName`
    /// collapses any failure to `nil`, never propagating an error.
    @Test func stubReturnsNilOnFailureWithoutThrowing() async {
        let sut = StubReverseGeocoding(behavior: .failure)
        let name = await sut.placeName(for: Coordinate(latitude: 30.05, longitude: 31.23))
        #expect(name == nil)
    }
}
