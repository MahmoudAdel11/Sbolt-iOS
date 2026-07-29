//
//  YallaMapViewRepresentable.swift
//  Yalla Go
//
//  Created by Mahmoud on 12/09/2024.
//

import Foundation
import SwiftUI
import MapKit

struct YallaMapViewRepresentable:UIViewRepresentable{
    
    let mapView = MKMapView()
    let locationManager = LocationManager.shared
    @Binding var mapState: MapViewState
    @EnvironmentObject var locationViewModel : LocationSearchViewModel
   
    
    func makeUIView(context: Context) -> some UIView {
        //.......
        mapView.delegate = context.coordinator
        //.......
        mapView.isRotateEnabled = false
        mapView.showsUserLocation = true
        // NOTE: camera is controlled manually below; do not also enable
        // `.follow`, otherwise the two fight and cause flicker/jumps.

        return mapView
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {
    
//        print("NOTE: map state is \(mapState)")
        
        switch mapState {
        case .noInput:
            context.coordinator.clearMapViewAndRecentreOnUserLocation()
            break
        case .searchingForLocation:
            break
        case .locationSelected:
            // Only (re)draw when the destination actually changed, so unrelated
            // @Published updates don't trigger redundant route recalculations.
            if let coordinate = locationViewModel.selectedYallaGoLocation?.coordinate,
               !coordinate.isEqual(to: context.coordinator.currentDestinationCoordinate) {
                context.coordinator.currentDestinationCoordinate = coordinate
                context.coordinator.addAndSelectAnnotation(withcoordinate: coordinate)
                context.coordinator.configerPolyline(withDestinationCoordinate: coordinate)
            }
            break

        }
        //        if mapState == .noInput  {
//            context.coordinator.clearMapViewAndRecentreOnUserLocation()
//        }
    }
    func makeCoordinator() -> MapCoordinator {
        return MapCoordinator(parent:self)
    }
    
}

private extension CLLocationCoordinate2D {
    /// Coordinate equality within a small tolerance, used to avoid redrawing
    /// the route for what is effectively the same destination.
    func isEqual(to other: CLLocationCoordinate2D?,
                 epsilon: CLLocationDegrees = 0.00001) -> Bool {
        guard let other else { return false }
        return abs(latitude - other.latitude) < epsilon
            && abs(longitude - other.longitude) < epsilon
    }
}
extension YallaMapViewRepresentable{
    //.........MKMapViewDelegate
    class MapCoordinator: NSObject,MKMapViewDelegate {
        
        // NOTE : properties
        
        let parent : YallaMapViewRepresentable
        var userLocationCoordinate :CLLocationCoordinate2D?
        var currentRegion :MKCoordinateRegion?
        /// Destination the route/annotation are currently drawn for.
        var currentDestinationCoordinate :CLLocationCoordinate2D?
        private var hasSetInitialRegion = false
        
        // NOTE : Lifecycle

        //.......
       init(parent : YallaMapViewRepresentable) {
           self.parent=parent
           super.init()
        }
        // NOTE : MKMapViewDelegate

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            self.userLocationCoordinate = userLocation.coordinate
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
                , span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05 ))
            // to update current region
            self.currentRegion = region

            // Only recentre once, on the first fix. Recentring on every update
            // fights MapKit's own dot movement and causes camera flicker/jumps.
            if !hasSetInitialRegion {
                hasSetInitialRegion = true
                parent.mapView.setRegion(region, animated: true)
            }
        }
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let polyline = MKPolylineRenderer(overlay: overlay)
            polyline.strokeColor = .systemBlue
            polyline.lineWidth = 6
            return polyline
        }
        
        // NOTE : helper
        func addAndSelectAnnotation(withcoordinate coordinate: CLLocationCoordinate2D){
            parent.mapView.removeAnnotations(parent.mapView.annotations)
            let anno = MKPointAnnotation()
            anno.coordinate = coordinate
            parent.mapView.addAnnotation(anno)
            parent.mapView.selectAnnotation(anno , animated:true)
        }
        func configerPolyline(withDestinationCoordinate coordinate:CLLocationCoordinate2D){
            guard let userLocationCoordinates = self.userLocationCoordinate else { return }

            parent.locationViewModel.calculateRoute(from: userLocationCoordinates , to: coordinate) {  route in
                // Replace any previous route instead of stacking polylines.
                self.parent.mapView.removeOverlays(self.parent.mapView.overlays)
                self.parent.mapView.addOverlay(route.polyline)
                let rect = self.parent.mapView.mapRectThatFits(route.polyline.boundingMapRect,edgePadding:
                        .init(top: 64, left: 32, bottom: 500, right: 32))
                self.parent.mapView.setRegion(MKCoordinateRegion(rect), animated: true )
            }
            
            
        }
      
        // func to clear map view ........
        func clearMapViewAndRecentreOnUserLocation(){
            parent.mapView.removeAnnotations(parent.mapView.annotations)
            parent.mapView.removeOverlays(parent.mapView.overlays)
            currentDestinationCoordinate = nil

            if let currentRegion = currentRegion {
                parent.mapView.setRegion(currentRegion, animated: true)
            }
        }

    }
}
