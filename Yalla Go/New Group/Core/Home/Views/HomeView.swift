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
    /// Source for the idle-state greeting header's username — injected at
    /// the app root (`Yalla_GoApp`), so it's already available here without
    /// any new wiring.
    @EnvironmentObject var session: AppSessionStore
    /// Owned here (not inside `RideRequestView`) so it persists across this
    /// screen's own `mapState`-driven show/hide of `RideRequestView`, and is
    /// available to check for a recovered ride even before the rider has
    /// picked a destination — see `checkForActiveRide()`.
    @StateObject private var bookingViewModel = TripBookingDependencies().makeTripBookingViewModel()
    /// Backs the idle-state "Recent trips" section — same data/use case
    /// `TripHistoryView` shows, just capped to 3 items there.
    @StateObject private var recentTripsViewModel = TripHistoryDependencies().makeTripHistoryViewModel()

    /// Map preview height while idle (`.noInput`) — "prominent but not
    /// dominant," since this is a small preview, not the full interactive
    /// map shown once actively searching/booking.
    private let mapPreviewHeight: CGFloat = 200

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                // Frame/clip are conditional on VALUES only (never wrapped in
                // its own `if/else` branch) so this stays the same view
                // instance across `mapState` changes — branching would tear
                // down and recreate the `UIViewRepresentable`'s coordinator
                // (region, annotations) on every idle <-> active transition.
                YallaMapViewRepresentable(mapState: $mapState)
                    .frame(height: mapState == .noInput ? mapPreviewHeight : nil)
                    .background(AppColors.backgroundSubtle)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: mapState == .noInput ? AppRadius.card : 0,
                            style: .continuous
                        )
                    )
                    .padding(.horizontal, mapState == .noInput ? AppSpacing.lg : 0)
                    .padding(.top, mapState == .noInput ? 60 : 0)
                    .ignoresSafeArea(mapState == .noInput ? [] : .all)

                if mapState == .searchingForLocation {
                    LocationSearchView(mapState: $mapState)
                } else if mapState == .noInput {
                    idleContent
                }

                MapActionButton(mapState: $mapState)
                    .padding(.leading)
                    .padding(.top, 5)
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
            if recentTripsViewModel.trips.isEmpty { recentTripsViewModel.loadTripHistory() }
        }
    }

    /// Search bar + recent trips, stacked below the shrunk map preview.
    /// A fixed top spacer (rather than nesting this inside the map's own
    /// layout) keeps the map view's declaration site untouched — see the
    /// identity-preservation note above.
    private var idleContent: some View {
        VStack(spacing: AppSpacing.lg) {
            Color.clear.frame(height: 60 + mapPreviewHeight + AppSpacing.lg)

            greetingHeader

            LocationSearchActivationView()
                .onTapGesture {
                    withAnimation(.spring()) {
                        mapState = .searchingForLocation
                    }
                }

            ScrollView {
                RecentTripsSection(viewModel: recentTripsViewModel) { trip in
                    let formatter = TripFormatter()
                    locationViewModel.selectDestination(
                        title: formatter.placeName(trip.dropoffAddress, fallback: trip.destinationCoordinate),
                        coordinate: trip.destinationCoordinate
                    )
                    withAnimation(.spring()) {
                        mapState = .locationSelected
                    }
                }
            }
        }
    }

    /// "Good morning / afternoon / evening, [username]" — new for this task;
    /// no such header existed anywhere in the codebase before (confirmed by
    /// a repo-wide search), so this isn't restoring dropped functionality.
    /// Falls back to no name (rather than hiding the row) if `currentUser`
    /// hasn't loaded yet, since Home can appear before the session finishes
    /// resolving.
    private var greetingHeader: some View {
        Text(greetingText)
            .font(.title2.weight(.semibold))
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.lg)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        switch hour {
        case 5..<12: timeOfDay = "Good morning"
        case 12..<17: timeOfDay = "Good afternoon"
        default: timeOfDay = "Good evening"
        }
        guard let username = session.currentUser?.username else { return timeOfDay }
        return "\(timeOfDay), \(username)"
    }

}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(LocationSearchViewModel())
            .environmentObject(AppSessionStore())
    }
}
