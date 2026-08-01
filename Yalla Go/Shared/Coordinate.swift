//
//  Coordinate.swift
//  Yalla Go
//
//  Created by Mahmoud on 30/07/2026.
//

import Foundation

/// Plain, `Equatable` latitude/longitude pair shared across feature domains.
/// Keeps domain models testable and free of CoreLocation, which does not
/// conform to `Equatable`. Single source of truth for a domain coordinate.
struct Coordinate: Equatable {
    let latitude: Double
    let longitude: Double
}
