//
//  ReverseGeocoding.swift
//  Yalla Go
//

import CoreLocation

/// Abstraction over `CLGeocoder` so callers (view models) can be exercised in
/// tests without hitting Apple's networked geocoding service — mirrors
/// `RouteRepository`'s pattern for the same reason.
protocol ReverseGeocoding {
    /// Resolves a coordinate to a human-readable place name. Never throws —
    /// per product decision, a resolution failure (offline, no result,
    /// timeout) must never block ride creation, so any failure collapses to
    /// `nil` rather than propagating.
    func placeName(for coordinate: Coordinate) async -> String?
}

/// `CLGeocoder`-backed implementation used in production. Free, on-device
/// first with an Apple-server fallback — no third-party geocoding service
/// integration, per the confirmed client-side-only decision.
struct CLGeocoderReverseGeocoding: ReverseGeocoding {

    func placeName(for coordinate: Coordinate) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            return placemarks.first.flatMap(placeName(from:))
        } catch {
            return nil
        }
    }

    /// Prefers the most specific human-readable component available,
    /// falling back progressively broader — a coordinate in a named
    /// neighborhood ("New Cairo") is more useful to a rider than a bare
    /// locality/city name, but either beats nothing.
    private func placeName(from placemark: CLPlacemark) -> String? {
        placemark.name ?? placemark.subLocality ?? placemark.locality ?? placemark.administrativeArea
    }
}
