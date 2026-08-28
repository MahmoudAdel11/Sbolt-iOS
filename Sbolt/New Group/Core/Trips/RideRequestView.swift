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
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject private var session: AppSessionStore
    /// Injected (not owned via `@StateObject`) so `HomeView` can hold a single
    /// persistent instance across this view's presence/absence — recovering a
    /// pending ride (see `checkForActiveRide()`) needs the same view model
    /// instance to still exist even before this view is first shown.
    @ObservedObject var bookingViewModel: TripBookingViewModel
    @StateObject private var favoritePlacesViewModel = FavoritePlacesDependencies().makeFavoritePlacesViewModel()
    @State private var isChoosingSavedPlace = false
    @State private var isSavingDestinationAsPlace = false
    /// Drag-to-expand state for the collapsed/expanded bottom sheet — purely
    /// visual (which layout renders), no business logic attached.
    @State private var isExpanded = false

    var body: some View {
        Group {
            if bookingViewModel.isIdle {
                bookingForm
            } else {
                TripBookingStatusView(viewModel: bookingViewModel)
                    .background(
                        BottomSheetShape(radius: 20)
                            .fill(AppColors.backgroundPrimary)
                    )
                    .background(
                        AppColors.backgroundPrimary
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

    // MARK: - Booking form (destination + tier selection)

    private var bookingForm: some View {
        VStack(spacing: AppSpacing.lg) {
            dragHandle
            routeSummary

            if isExpanded {
                expandedContent
            } else {
                collapsedContent
            }
        }
        .padding(.top, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.lg)
        .background(
            BottomSheetShape(radius: 20)
                .fill(AppColors.backgroundPrimary)
        )
        .background(
            AppColors.backgroundPrimary
                .ignoresSafeArea(.container, edges: .bottom)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isExpanded)
    }

    private var dragHandle: some View {
        Capsule()
            .fill(AppColors.borderHairline)
            .frame(width: 50, height: 6)
            .contentShape(Rectangle().inset(by: -12)) // easier drag target than the visible handle alone
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onEnded { value in
                        if value.translation.height < -20 { isExpanded = true }
                        else if value.translation.height > 20 { isExpanded = false }
                    }
            )
            .onTapGesture { isExpanded.toggle() }
            .accessibilityIdentifier("ride_request_sheet_handle")
    }

    /// "Current location → [destination]" — the same underlying selection
    /// (`selectedYallaGoLocation`) the old pickup/dropoff rows already read,
    /// just condensed to a single line per the confirmed design. The inline
    /// save-star only appears here in the collapsed state — the expanded
    /// state has its own dedicated "Choose from Saved Places" row instead.
    private var routeSummary: some View {
        HStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Text("Current location")
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.semibold))
                Text(locationViewModel.selectedYallaGoLocation?.titel ?? "")
                    .lineLimit(1)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppColors.textPrimary)

            Spacer()

            if !isExpanded {
                Button {
                    isSavingDestinationAsPlace = true
                } label: {
                    Image(systemName: "star")
                        .foregroundStyle(AppColors.accent)
                        .padding(AppSpacing.xs)
                        .background(AppColors.accentTint, in: Circle())
                }
                .accessibilityLabel("Save this place")
                .accessibilityIdentifier("save_destination_as_place_button")
            }
        }
    }

    // MARK: - Collapsed state

    /// A plain (non-scrolling) `HStack`, not `ScrollView(.horizontal)` — the
    /// tier count is fixed at exactly 3 (`RideType.allCases`), so there's
    /// nothing to scroll to, and a `ScrollView` gives its content unbounded
    /// width, which is exactly what was preventing the cards' own
    /// `.frame(maxWidth: .infinity)` from having anything to expand against
    /// (leftover empty space to the right of the last card).
    private var collapsedContent: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(RideType.allCases) { type in
                    RideTierCard(
                        tier: type,
                        price: price(for: type),
                        isSelected: selectedRideType == type,
                        style: .compact
                    )
                    .onTapGesture { selectedRideType = type }
                    .accessibilityIdentifier("ride_tier_\(type.rawValue)_button")
                }
            }

            splitConfirmButton
        }
    }

    // MARK: - Expanded state

    private var expandedContent: some View {
        VStack(spacing: AppSpacing.lg) {
            savedPlacesRow

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Choose your ride")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textMuted)

                ForEach(RideType.allCases) { type in
                    RideTierCard(
                        tier: type,
                        price: price(for: type),
                        isSelected: selectedRideType == type,
                        style: .expanded
                    )
                    .onTapGesture { selectedRideType = type }
                    .accessibilityIdentifier("ride_tier_\(type.rawValue)_button")
                }
            }

            estimateNote

            paymentRow

            splitConfirmButton
        }
    }

    private var savedPlacesRow: some View {
        Button {
            isChoosingSavedPlace = true
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "star.fill")
                    .foregroundStyle(AppColors.accent)
                Text("Choose from Saved Places")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textDisabled)
            }
            .padding(AppSpacing.md)
            .background(AppColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
    }

    /// Pre-request-only estimate, client-side, never sent to the backend —
    /// the real, authoritative fare comes back on `Trip.fare` once the ride
    /// actually exists (see `TripBookingStatusView`) and is what's shown
    /// from then on.
    private var estimateNote: some View {
        HStack {
            Text("Estimated fare")
            Spacer()
            Text("Estimate only — final fare may vary")
        }
        .font(.caption)
        .foregroundStyle(AppColors.textMuted)
    }

    private var paymentRow: some View {
        HStack(spacing: AppSpacing.md) {
            Text("VISA")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppColors.textOnAccent)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.accent, in: RoundedRectangle(cornerRadius: AppRadius.card / 3, style: .continuous))
            Text("•••• 123")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textDisabled)
        }
        .padding(AppSpacing.md)
        .background(AppColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    // MARK: - Shared confirm control

    /// Left half: "Confirm ride" on a solid accent fill. Right half: the
    /// price on a plain background — one tappable control, visually split
    /// into two halves inside a single pill.
    private var splitConfirmButton: some View {
        Button {
            confirmRide()
        } label: {
            HStack(spacing: 0) {
                Text("Confirm ride")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppColors.accent)

                Text(estimatedFare.toCurrency())
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColors.accentTextDark)
                    .padding(.horizontal, AppSpacing.lg)
                    .frame(height: 52)
                    .background(AppColors.backgroundPrimary)
            }
            .clipShape(Capsule())
            .overlay(Capsule().stroke(AppColors.accent, lineWidth: 1))
        }
        .disabled(locationViewModel.userLocation == nil || locationViewModel.selectedYallaGoLocation == nil)
        .opacity(locationViewModel.userLocation == nil || locationViewModel.selectedYallaGoLocation == nil ? 0.5 : 1)
        .accessibilityIdentifier("confirm_ride_button")
    }

    private func price(for type: RideType) -> Double {
        locationViewModel.computeRidePrice(forType: type)
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
            .environmentObject(LocationSearchViewModel())
            .environmentObject(AppSessionStore())
    }
}
