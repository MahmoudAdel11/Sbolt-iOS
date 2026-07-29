//
//  TripCoordinate.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation

/// Plain, `Equatable` coordinate for the domain layer. Keeps `Trip` testable
/// and free of CoreLocation, which does not conform to `Equatable`.
struct TripCoordinate: Equatable {
    let latitude: Double
    let longitude: Double
}
