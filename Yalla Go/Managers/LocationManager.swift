//
//  LocationManager.swift
//  Yalla Go
//
//  Created by Mahmoud on 13/09/2024.
//

import Foundation
import CoreLocation
class LocationManager : NSObject ,ObservableObject{
    private let locationManager = CLLocationManager()
    static let shared = LocationManager()
    @Published var userLocation : CLLocationCoordinate2D?

    private let updatePolicy = LocationUpdatePolicy()
    private var lastAcceptedLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest//............best user locc    aa
        locationManager.distanceFilter = 10
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
}

extension LocationManager :CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Use the most recent fix, then let the policy reject stale, invalid,
        // duplicate, or meaningless updates before publishing.
        guard let location = locations.last,
              updatePolicy.shouldAccept(location, over: lastAcceptedLocation) else { return }

        lastAcceptedLocation = location
        self.userLocation = location.coordinate
    }
}
