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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(viewModel.favoritePlaces) { place in
                Button {
                    onSelect(place)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: place.icon)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(place.title).font(.body).foregroundStyle(.primary)
                            Text(place.address).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityIdentifier("saved_place_row_\(place.id)")
            }
            .listStyle(.plain)
        }
    }
}

#if DEBUG
struct SavedPlacePickerView_Previews: PreviewProvider {
    static var previews: some View {
        SavedPlacePickerView(onSelect: { _ in })
    }
}
#endif
