//
//  AvailableRidesMapViewRepresentable.swift
//  Yalla Go
//

import SwiftUI
import MapKit

/// Purpose-built map for the driver's available-rides screen: one pickup pin
/// per available ride, plus a second dropoff pin for whichever ride is
/// currently selected (no connecting line between them — a straight
/// polyline was tried and looked unnatural), the native blue dot for the
/// driver's own location, and a manual recenter trigger. Deliberately
/// separate from `YallaMapViewRepresentable` (the rider's single-destination
/// search map) rather than extending it — that component is structurally
/// coupled to `LocationSearchViewModel`/`MapViewState`, neither of which
/// applies here, and its "remove-all-then-add-one" annotation model is wrong
/// for showing several simultaneous ride pins.
struct AvailableRidesMapViewRepresentable: UIViewRepresentable {
    let mapView = MKMapView()
    let rides: [Trip]
    /// The ride whose bottom sheet is currently open, if any — drives the
    /// dropoff pin; `nil` removes it.
    let selectedRide: Trip?
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
        context.coordinator.updateDropoffPin(for: selectedRide)
        context.coordinator.autoZoomIfNeeded(rides: rides)
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
        private var currentDropoffRideID: String?
        /// Resets for free whenever this coordinator itself is rebuilt —
        /// which happens automatically every time the driver goes offline
        /// and back online, since `DriverHomeView` only shows this map while
        /// online with no active ride. See `AutoZoomTrigger`'s doc comment.
        private var zoomedRideIDs: Set<String> = []

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

        /// Dropoff pin for the selected ride only — no connecting line (a
        /// straight polyline was tried and looked unnatural; two distinct
        /// pins read more clearly). Only one dropoff pin is ever on the map
        /// at a time: a no-op short-circuits when the selection hasn't
        /// actually changed, so an unrelated poll-driven `updateUIView`
        /// doesn't re-add it every tick.
        func updateDropoffPin(for ride: Trip?) {
            guard ride?.id != currentDropoffRideID else { return }
            let existingDropoffs = parent.mapView.annotations.compactMap { $0 as? DropoffAnnotation }
            if !existingDropoffs.isEmpty { parent.mapView.removeAnnotations(existingDropoffs) }
            currentDropoffRideID = ride?.id
            guard let ride else { return }
            let annotation = DropoffAnnotation(rideID: ride.id)
            annotation.coordinate = CLLocationCoordinate2D(latitude: ride.destinationCoordinate.latitude,
                                                            longitude: ride.destinationCoordinate.longitude)
            annotation.title = "Dropoff"
            parent.mapView.addAnnotation(annotation)
        }

        /// Fires whenever a genuinely new ride ID shows up — see `AutoZoomTrigger`.
        func autoZoomIfNeeded(rides: [Trip]) {
            let incomingIDs = Set(rides.map(\.id))
            guard AutoZoomTrigger.shouldZoom(zoomedRideIDs: zoomedRideIDs, incomingIDs: incomingIDs) else { return }
            zoomedRideIDs.formUnion(incomingIDs)
            fitCamera(toDriverAnd: rides)
        }

        /// Builds the true bounding `MKMapRect` across the driver + every
        /// currently-visible ride's pickup coordinate, then fits it exactly
        /// via `setVisibleMapRect(_:edgePadding:animated:)`.
        ///
        /// Previously used `mapRectThatFits(_:edgePadding:)`, which
        /// preserves the map's *current* zoom level rather than computing a
        /// fresh one — when the target bounding rect is larger than what's
        /// already visible (the common case here: the camera starts at a
        /// tight ~0.05°-span region from the first location fix, then
        /// several scattered rides appear), it fails to actually zoom out
        /// far enough, which reads as "centered on a midpoint" rather than
        /// a real fit. `setVisibleMapRect` computes zoom fresh from the
        /// given rect regardless of the current camera, so it doesn't have
        /// this limitation.
        private func fitCamera(toDriverAnd rides: [Trip]) {
            var coordinates = rides.map {
                CLLocationCoordinate2D(latitude: $0.pickupCoordinate.latitude, longitude: $0.pickupCoordinate.longitude)
            }
            if let userCoordinate = parent.mapView.userLocation.location?.coordinate {
                coordinates.append(userCoordinate)
            }
            guard !coordinates.isEmpty else { return }

            var boundingRect = MKMapRect.null
            for coordinate in coordinates {
                let point = MKMapPoint(coordinate)
                boundingRect = boundingRect.union(MKMapRect(origin: point, size: MKMapSize(width: 0, height: 0)))
            }

            parent.mapView.setVisibleMapRect(
                boundingRect,
                edgePadding: UIEdgeInsets(top: 80, left: 40, bottom: 260, right: 40),
                animated: true
            )
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

        /// Pickup pins and the user-location dot keep MapKit's default
        /// appearance (`nil`); only the dropoff pin gets a distinct
        /// marker — checkered flag glyph, purple tint — so it reads clearly
        /// as "where this ride ends" without a connecting line.
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is DropoffAnnotation else { return nil }
            let identifier = "DropoffAnnotation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.markerTintColor = .systemPurple
            view.glyphImage = UIImage(systemName: "flag.checkered")
            view.canShowCallout = true
            return view
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

/// The dropoff pin shown only for the currently-selected ride. A distinct
/// type from `RideAnnotation` so the coordinator can find/remove it (and the
/// delegate can style it) without confusing it with an available-ride pin.
final class DropoffAnnotation: NSObject, MKAnnotation {
    let rideID: String
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?

    init(rideID: String) {
        self.rideID = rideID
        self.coordinate = CLLocationCoordinate2D()
        super.init()
    }
}
