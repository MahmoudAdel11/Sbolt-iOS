//
//  RideRequestView.swift
//  Yalla Go
//
//  Created by Mahmoud on 09/03/2025.
//

import SwiftUI

struct RideRequestView: View {
    /// Always has a selection — the tier picker below defaults to `.economy`
    /// and there's no way to deselect, so the request body always has a
    /// valid, non-optional tier to send.
    @State private var selectedRideType: RideType = .economy
    @EnvironmentObject var locationViewModel:LocationSearchViewModel
    @EnvironmentObject private var session: AppSessionStore
    /// Injected (not owned via `@StateObject`) so `HomeView` can hold a single
    /// persistent instance across this view's presence/absence — recovering a
    /// pending ride (see `checkForActiveRide()`) needs the same view model
    /// instance to still exist even before this view is first shown.
    @ObservedObject var bookingViewModel: TripBookingViewModel
    @StateObject private var favoritePlacesViewModel = FavoritePlacesDependencies().makeFavoritePlacesViewModel()
    @State private var isChoosingSavedPlace = false
    @State private var isSavingDestinationAsPlace = false

    var body: some View {
        Group {
            if bookingViewModel.isIdle {
                bookingForm
            } else {
                TripBookingStatusView(viewModel: bookingViewModel)
                    .background(
                        BottomSheetShape(radius: 20)
                            .fill(Color.white)
                    )
                    .background(
                        Color.white
                            .ignoresSafeArea(.container, edges: .bottom)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: bookingViewModel.isIdle)
        .onChange(of: bookingViewModel.isSessionExpired) { expired in
            if expired { session.signOut() }
        }
        .sheet(isPresented: $isChoosingSavedPlace) {
            SavedPlacePickerView { place in
                locationViewModel.selectDestination(title: place.title, coordinate: place.coordinate)
                isChoosingSavedPlace = false
            }
        }
        // Sheet-over-sheet from the booking form itself, sharing this view's
        // own `favoritePlacesViewModel` — saving doesn't touch or clear
        // `locationViewModel.selectedYallaGoLocation`, so the ride request
        // in progress is undisturbed underneath.
        .sheet(isPresented: $isSavingDestinationAsPlace) {
            if let coordinate = destinationCoordinate {
                FavoritePlaceFormView(viewModel: favoritePlacesViewModel, lockedCoordinate: coordinate)
            }
        }
    }

    // The original ride-request card. Shown while no booking is in progress.
    private var bookingForm: some View {
        VStack{
            Capsule()
                .foregroundColor(Color(.systemGray5))
                .frame(width: 50, height: 6)
                .padding(.top,8)
            // trip info
            HStack{
                VStack{
                    Circle()
                        .fill(Color(.systemGray))
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Color(.systemGray))
                        .frame(width: 1, height: 32)
                    Rectangle()
                        .fill(Color(.black))
                        .frame(width: 8, height: 8)
                }
                
                VStack(alignment: .leading, spacing: 24){
                    HStack{
                        Text("Current location" )
                            .font(.system(size: 16, weight: .semibold ))
                            .foregroundColor(Color(.gray))
                        Spacer()
                        Text(locationViewModel.pickupTime ?? "")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.gray))
                    }.padding(.bottom,10)
                                            
                    HStack{
                        if let location = locationViewModel.selectedYallaGoLocation {
                            Text(location.titel)
                                .font(.system(size: 16, weight: .semibold  ))
                            Button {
                                isSavingDestinationAsPlace = true
                            } label: {
                                Image(systemName: "star")
                                    .foregroundColor(.gray)
                            }
                            .accessibilityLabel("Save this place")
                            .accessibilityIdentifier("save_destination_as_place_button")
                        }
                        Spacer()
                        Text(locationViewModel.dropoffTime ?? "")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.gray))
                    }
                }
                .padding(.leading,8)
                                            
            } .padding()

            Button {
                isChoosingSavedPlace = true
            } label: {
                Label("Choose from Saved Places", systemImage: "star.fill")
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()
                .padding(.vertical, 8)

            tierPicker

            // Pre-request-only estimate, client-side, never sent to the
            // backend — the real, authoritative fare comes back on
            // `Trip.fare` once the ride actually exists
            // (see TripBookingStatusView) and is what's shown from then on.
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Estimated fare")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Text(estimatedFare.toCurrency())
                        .font(.system(size: 16, weight: .bold))
                }
                Text("Estimate only — final fare may vary.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()
                .padding(.vertical, 8)
            
        // payment
            HStack( spacing: 12){
            Text("visa")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(6)
                    .background(.blue)
                    .cornerRadius(4)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                Text("*****  123").fontWeight(.bold)
                Spacer()
                Image(systemName: "chevron.right")
                    .imageScale(.medium)
                    .padding()
            }
            .frame(height: 50)
            .background(Color(.systemGroupedBackground))
            .cornerRadius(10)
            .padding(.horizontal)
        
                        // confirm trip
            Button {
                confirmRide()
            } label: {
                Text("CONFIRM RIDE")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
            .disabled(locationViewModel.userLocation == nil || locationViewModel.selectedYallaGoLocation == nil)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            BottomSheetShape(radius: 20)
                .fill(Color.white)
        )
        .background(
            Color.white
                .ignoresSafeArea(.container, edges: .bottom)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)
    }

    /// Three tappable tier options, matching this file's existing inline
    /// button-styling convention (the "visa" payment badge above uses the
    /// same solid-background/rounded-corner shape) rather than introducing
    /// a new component.
    private var tierPicker: some View {
        HStack(spacing: 10) {
            ForEach(RideType.allCases) { type in
                Button {
                    selectedRideType = type
                } label: {
                    Text(type.description)
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedRideType == type ? Color.blue : Color(.systemGroupedBackground))
                        .foregroundColor(selectedRideType == type ? .white : .black)
                        .cornerRadius(10)
                }
                .accessibilityIdentifier("ride_tier_\(type.rawValue)_button")
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var estimatedFare: Double {
        locationViewModel.computeRidePrice(forType: selectedRideType)
    }

    private var destinationCoordinate: Coordinate? {
        guard let coordinate = locationViewModel.selectedYallaGoLocation?.coordinate else { return nil }
        return Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    private func confirmRide() {
        guard let userCoordinate = locationViewModel.userLocation,
              let destination = locationViewModel.selectedYallaGoLocation?.coordinate else { return }
        let pickup = Coordinate(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        let dropoff = Coordinate(latitude: destination.latitude, longitude: destination.longitude)
        bookingViewModel.confirmTrip(pickup: pickup, dropoff: dropoff, tier: selectedRideType)
    }
}




/// Rounds only the top-left and top-right corners so the sheet merges
/// seamlessly with the Tab Bar below it.
private struct BottomSheetShape: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

struct RideRequestView_Previews: PreviewProvider {
    static var previews: some View {
        RideRequestView(bookingViewModel: TripBookingDependencies().makeTripBookingViewModel())
    }
}
