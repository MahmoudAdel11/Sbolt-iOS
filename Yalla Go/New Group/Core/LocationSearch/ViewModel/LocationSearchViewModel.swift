//
//  LocationSearchViewModel.swift
//  Yalla Go
//
//  Created by Mahmoud on 31/01/2025.
//

import Foundation
import MapKit
class LocationSearchViewModel : NSObject , ObservableObject {

    @Published private(set) var results = [MKLocalSearchCompletion]()
    @Published private(set) var selectedYallaGoLocation: YallaGoLocation?
    @Published private(set) var pickupTime : String?
    @Published private(set) var dropoffTime : String?

    private let searchCompleter = MKLocalSearchCompleter()
    private let routeRepository: RouteRepository

    /// In-flight location lookup. A newer selection cancels the previous one
    /// so a slower, older response can never overwrite the latest selection.
    private var locationSelectionTask: Task<Void, Never>?
    /// In-flight route calculation, cancelled the same way when the destination changes.
    private var routeTask: Task<Void, Never>?

    var  queryFragment:  String = ""{
        didSet{
            searchCompleter.queryFragment = queryFragment
        }
    }
    var userLocation :CLLocationCoordinate2D?
    //
     init(routeRepository: RouteRepository = MapKitRouteRepository()){
         self.routeRepository = routeRepository
         super.init()
         searchCompleter.delegate = self
         //.......queryFragment ...... for  search completer
         searchCompleter.queryFragment = queryFragment
    }

    deinit {
        // Stop any in-flight lookup/route work so it can't outlive the view model.
        locationSelectionTask?.cancel()
        routeTask?.cancel()
    }
    func selecteLocation(_ localSearch:MKLocalSearchCompletion){
        // A newer selection makes any previous lookup obsolete.
        locationSelectionTask?.cancel()
        locationSelectionTask = Task { @MainActor in
            do {
                let location = try await routeRepository.resolveLocation(for: localSearch)
                try Task.checkCancellation()
                self.selectedYallaGoLocation = location
                print(" DEBUG : location cordinate \(location.coordinate)")
            } catch is CancellationError {
                // Superseded by a newer selection; ignore.
            } catch {
                print(" DEBUG : location search failed with error\(error.localizedDescription)")
            }
        }
    }
    /// Clears the current destination selection. Exposed as an intent so views
    /// send an action instead of mutating the view model's state directly.
    func clearSelectedLocation(){
        locationSelectionTask?.cancel()
        selectedYallaGoLocation = nil
    }
    func computeRidePrice(forType type:RideType)-> Double{
        guard let destCoordinate = selectedYallaGoLocation?.coordinate else { return 0.0}
        guard let userCoordinate = self.userLocation else { return 0.0 }

        let userLocation = CLLocation(latitude: userCoordinate.latitude,
                                      longitude: userCoordinate.longitude)
        let destination = CLLocation(latitude: destCoordinate.latitude,
                                     longitude: destCoordinate.longitude)
        let tripDestanceInMeters = userLocation.distance(from: destination)
        return type.computePrice(for: tripDestanceInMeters)
    }
    func calculateRoute(from userLocation: CLLocationCoordinate2D ,
                        to  destination  : CLLocationCoordinate2D
                        , completion:@escaping(MKRoute) -> Void) {
        // A newer destination makes any previous route request obsolete.
        routeTask?.cancel()
        routeTask = Task { @MainActor in
            do {
                let route = try await routeRepository.calculateRoute(from: userLocation, to: destination)
                try Task.checkCancellation()
                self.configurePickupAndDropoffTimes(with: route.expectedTravelTime)
                completion(route)
            } catch is CancellationError {
                // Superseded by a newer destination; ignore.
            } catch {
                print("NOTE : failed to get directions with error \(error.localizedDescription)")
            }
        }
    }
    private func configurePickupAndDropoffTimes(with expectedTravelTime:Double){
        let forrmatter = DateFormatter()
        forrmatter.dateFormat = "hh:mm a"
        pickupTime = forrmatter.string(from: Date())
        dropoffTime =  forrmatter.string(from: Date() + expectedTravelTime)
    }

}
extension LocationSearchViewModel : MKLocalSearchCompleterDelegate{
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.results  = completer.results
    }


}
