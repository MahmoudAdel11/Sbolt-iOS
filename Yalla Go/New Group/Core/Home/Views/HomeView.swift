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
            if mapState == .locationSelected {
                RideRequestView()
                    .transition(.move(edge: .bottom))
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .onReceive(LocationManager.shared.$userLocation) {
                location in
            if let location = location {
                locationViewModel.userLocation = location
            }
            }
    }
    
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
