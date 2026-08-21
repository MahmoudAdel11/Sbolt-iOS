//
//  AvailableRidesMapViewRepresentable.swift
//  Yalla Go
//

import SwiftUI
import MapKit

/// Purpose-built map for the driver's available-rides screen: one pin per
/// ride (at pickup only, no route line), the native blue dot for the
/// driver's own location, and a manual recenter trigger. Deliberately
/// separate from `YallaMapViewRepresentable` (the rider's single-destination
/// search map) rather than extending it — that component is structurally
/// coupled to `LocationSearchViewModel`/`MapViewState`, neither of which
/// applies here, and its "remove-all-then-add-one" annotation model is wrong
/// for showing several simultaneous ride pins.
struct AvailableRidesMapViewRepresentable: UIViewRepresentable {
    let mapView = MKMapView()
    let rides: [Trip]
    @Binding var recenterTrigger: Bool
    let onSelectRide: (String) -> Void

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = false
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.diffAnnotations(rides: rides)
        if recenterTrigger {
            context.coordinator.recenterOnUserLocation()
            DispatchQueue.main.async { recenterTrigger = false }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private let parent: AvailableRidesMapViewRepresentable
        private var hasSetInitialRegion = false

        init(parent: AvailableRidesMapViewRepresentable) {
            self.parent = parent
        }

        /// Adds/removes only the delta between what's pinned and the latest
        /// batch — a ride present in both is left completely untouched, so
        /// an open selection/sheet survives a poll tick without flicker.
        func diffAnnotations(rides: [Trip]) {
            let mapView = parent.mapView
            let existing = mapView.annotations.compactMap { $0 as? RideAnnotation }
            let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.rideID, $0) })
            let ridesByID = Dictionary(uniqueKeysWithValues: rides.map { ($0.id, $0) })

            let diff = RideAnnotationDiff.compute(existingIDs: Set(existingByID.keys),
                                                  incomingIDs: Set(ridesByID.keys))

            let toRemove = diff.toRemove.compactMap { existingByID[$0] }
            if !toRemove.isEmpty { mapView.removeAnnotations(toRemove) }

            let toAdd = diff.toAdd.compactMap { ridesByID[$0] }.map { ride -> RideAnnotation in
                let annotation = RideAnnotation(rideID: ride.id)
                annotation.coordinate = CLLocationCoordinate2D(latitude: ride.pickupCoordinate.latitude,
                                                                longitude: ride.pickupCoordinate.longitude)
                annotation.title = "Ride request"
                return annotation
            }
            if !toAdd.isEmpty { mapView.addAnnotations(toAdd) }
        }

        func recenterOnUserLocation() {
            guard let coordinate = parent.mapView.userLocation.location?.coordinate else { return }
            let region = MKCoordinateRegion(center: coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            parent.mapView.setRegion(region, animated: true)
        }

        // MARK: - MKMapViewDelegate

        /// Recentres once, on the first fix only — same rule as the rider
        /// map's own documented behavior: recentring on every location
        /// update fights MapKit's own dot movement and the driver's own
        /// pan/zoom. A poll tick never touches the camera at all.
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard !hasSetInitialRegion, let coordinate = userLocation.location?.coordinate else { return }
            hasSetInitialRegion = true
            let region = MKCoordinateRegion(center: coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            mapView.setRegion(region, animated: true)
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? RideAnnotation else { return }
            parent.onSelectRide(annotation.rideID)
        }
    }
}

/// Carries a ride ID alongside its pickup coordinate so a tapped pin can be
/// mapped back to the `Trip` it represents.
final class RideAnnotation: NSObject, MKAnnotation {
    let rideID: String
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?

    init(rideID: String) {
        self.rideID = rideID
        self.coordinate = CLLocationCoordinate2D()
        super.init()
    }
}
