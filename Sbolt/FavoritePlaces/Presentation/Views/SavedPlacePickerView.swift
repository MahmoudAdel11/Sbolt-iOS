//
//  SavedPlacePickerView.swift
//  Yalla Go
//

import SwiftUI

/// Sheet presented from ride booking to pick a saved place as the
/// destination. Purely a client-side convenience — selecting a place
/// pre-fills the existing coordinate field via `onSelect`; there is no
/// backend concept of a favourite-linked ride. Reuses
/// `FavoritePlacesViewModel`/`FavoritePlacesDependencies`, the same data
/// path as any future favourites-management screen — no second fetch path.
struct SavedPlacePickerView: View {
    @StateObject private var viewModel = FavoritePlacesDependencies().makeFavoritePlacesViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var isAdding = false
    let onSelect: (FavoritePlace) -> Void

    var body: some View {
        NavigationView {
            content
                .navigationTitle("Saved Places")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .task {
                    if viewModel.favoritePlaces.isEmpty { viewModel.loadFavorites() }
                }
                // Sheet-over-sheet: presented from the picker itself, sharing
                // the picker's own `viewModel` instance — a newly added place
                // lands straight in the same in-memory list the picker reads,
                // so it appears without dismissing/losing the ride-booking flow.
                .sheet(isPresented: $isAdding) {
                    FavoritePlaceFormView(viewModel: viewModel)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.favoritePlaces.isEmpty {
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage, viewModel.favoritePlaces.isEmpty {
            VStack(spacing: 12) {
                Text(errorMessage).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("Retry") { viewModel.loadFavorites() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "star.slash").font(.system(size: 40)).foregroundStyle(.secondary)
                Text("No saved places yet").font(.headline)
                addPlaceButton
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Always visible — not just an empty-state action — so a
                    // user with existing places can still add another without
                    // leaving the picker.
                    addPlaceButton

                    Text("Your places")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.accent)

                    VStack(spacing: AppSpacing.sm) {
                        ForEach(viewModel.favoritePlaces) { place in
                            Button {
                                onSelect(place)
                            } label: {
                                placeRow(place)
                            }
                            .accessibilityIdentifier("saved_place_row_\(place.id)")
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.backgroundPrimary)
        }
    }

    private func placeRow(_ place: FavoritePlace) -> some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 36, height: 36)
                Image(systemName: place.icon)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(place.title).font(.body).foregroundStyle(AppColors.textPrimary)
                Text(place.address).font(.caption).foregroundStyle(AppColors.textMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textDisabled)
        }
        .padding(AppSpacing.md)
        .background(AppColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    // NOTE: the design spec for this button describes a subtitle showing
    // "the destination address" — but this picker has no destination/address
    // in context (it exists to CHOOSE a destination, not save one already
    // selected; that flow already exists separately as RideRequestView's
    // star button -> FavoritePlaceFormView(lockedCoordinate:)). Restyled per
    // spec without fabricating an address subtitle with no backing data —
    // see this task's summary for the full flag.
    private var addPlaceButton: some View {
        Button {
            isAdding = true
        } label: {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(AppColors.accent)
                        .frame(width: 36, height: 36)
                    Image(systemName: "plus")
                        .foregroundStyle(.white)
                }
                Text("Add a Place")
                    .font(.body)
                    .foregroundStyle(AppColors.accentTextDark)
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(AppColors.accentTint, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(AppColors.accent, lineWidth: 1.5)
            )
        }
        .accessibilityIdentifier("saved_place_picker_add_button")
    }
}

#if DEBUG
struct SavedPlacePickerView_Previews: PreviewProvider {
    static var previews: some View {
        SavedPlacePickerView(onSelect: { _ in })
    }
}
#endif
