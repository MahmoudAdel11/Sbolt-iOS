//
//  RouteRepository.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import MapKit

/// Abstraction over MapKit lookups so the view model can be exercised
/// in tests without hitting Apple's networked services.
protocol RouteRepository {
    /// Resolves an autocomplete suggestion into a concrete map location.
    func resolveLocation(for completion: MKLocalSearchCompletion) async throws -> YallaGoLocation

    /// Calculates a route between two coordinates.
    func calculateRoute(from source: CLLocationCoordinate2D,
                         to destination: CLLocationCoordinate2D) async throws -> MKRoute
}

enum RouteRepositoryError: Error {
    case locationNotFound
    case routeNotFound
}

/// MapKit-backed implementation used in production.
struct MapKitRouteRepository: RouteRepository {

    func resolveLocation(for completion: MKLocalSearchCompletion) async throws -> YallaGoLocation {
        let request = MKLocalSearch.Request(completion: completion)
        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first else {
            throw RouteRepositoryError.locationNotFound
        }
        return YallaGoLocation(titel: completion.title, coordinate: item.placemark.coordinate)
    }

    func calculateRoute(from source: CLLocationCoordinate2D,
                        to destination: CLLocationCoordinate2D) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))

        let response = try await MKDirections(request: request).calculate()
        guard let route = response.routes.first else {
            throw RouteRepositoryError.routeNotFound
        }
        return route
    }
}
