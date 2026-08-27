//
//  HomeView.swift
//  Yalla Go
//
//  Created by Mahmoud on 11/09/2024.
//

import SwiftUI

struct HomeView: View {
    @State private var mapState = MapViewState.noInput
    @EnvironmentObject var locationViewModel:LocationSearchViewModel
    /// Owned here (not inside `RideRequestView`) so it persists across this
    /// screen's own `mapState`-driven show/hide of `RideRequestView`, and is
    /// available to check for a recovered ride even before the rider has
    /// picked a destination — see `checkForActiveRide()`.
    @StateObject private var bookingViewModel = TripBookingDependencies().makeTripBookingViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack (alignment: .top){
                YallaMapViewRepresentable(mapState: $mapState  )
                    .ignoresSafeArea()

                if mapState == .searchingForLocation {
                    LocationSearchView(mapState: $mapState)

                }else if mapState == .noInput {
                    LocationSearchActivationView()
                    .padding(.top,75)
                    .onTapGesture {
                        withAnimation(.spring()){
                            mapState = .searchingForLocation
                        }
                }
                }

                MapActionButton(mapState: $mapState)
                    .padding(.leading)
                    .padding(.top,5)
            }
            // Shown either because the rider picked a destination (normal
            // flow) or because a pending ride was recovered from the backend
            // (`bookingViewModel.isIdle == false`) — same sheet either way,
            // no separate recovery UI.
            if mapState == .locationSelected || !bookingViewModel.isIdle {
                RideRequestView(bookingViewModel: bookingViewModel)
                    .transition(.move(edge: .bottom))
            }
        }

        .onReceive(LocationManager.shared.$userLocation) {
                location in
            if let location = location {
                locationViewModel.userLocation = location
            }
            }
        // Checked on every Home-screen appearance (cold launch, returning
        // from another tab, etc.), not just cold launch - a no-op whenever a
        // booking flow is already in progress (see `checkForActiveRide`'s
        // own guard).
        .onAppear {
            bookingViewModel.checkForActiveRide()
        }
    }

}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
