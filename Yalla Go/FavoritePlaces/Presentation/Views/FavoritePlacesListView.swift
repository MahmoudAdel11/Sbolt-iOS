//
//  FavoritePlacesListView.swift
//  Yalla Go
//

import SwiftUI

/// Standalone favourite-places management screen, reachable from Profile:
/// list, add, edit (tap a row), delete (swipe). Binds to
/// `FavoritePlacesViewModel`; contains no business logic. Uses the exact
/// same view model/use cases/repository as `SavedPlacePickerView` — no
/// second data path.
struct FavoritePlacesListView: View {
    @StateObject private var viewModel: FavoritePlacesViewModel
    @EnvironmentObject private var session: AppSessionStore
    @State private var isAdding = false
    @State private var editingPlace: FavoritePlace?

    init(dependencies: FavoritePlacesDependencies = FavoritePlacesDependencies()) {
        _viewModel = StateObject(wrappedValue: dependencies.makeFavoritePlacesViewModel())
    }

    var body: some View {
        content
            .navigationTitle("Saved Places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isAdding = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add a place")
                    .accessibilityIdentifier("favorite_places_add_button")
                }
            }
            .task {
                if viewModel.favoritePlaces.isEmpty { viewModel.loadFavorites() }
            }
            .sheet(isPresented: $isAdding) {
                FavoritePlaceFormView(viewModel: viewModel)
            }
            .sheet(item: $editingPlace) { place in
                FavoritePlaceFormView(viewModel: viewModel, editing: place)
            }
            .onChange(of: viewModel.isSessionExpired) { expired in
                if expired { session.signOut() }
            }
    }

    // MARK: - State routing

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.favoritePlaces.isEmpty {
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("favorite_places_loading")
        } else if let errorMessage = viewModel.errorMessage, viewModel.favoritePlaces.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text(errorMessage)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("Retry") { viewModel.loadFavorites() }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("favorite_places_retry_button")
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("favorite_places_error_state")
        } else if viewModel.isEmpty {
            emptyState
        } else {
            list
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("No saved places yet")
                .font(.title2).bold()
            Text("Add a place for quick access when booking a ride.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add a Place") { isAdding = true }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("favorite_places_empty_add_button")
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("favorite_places_empty_state")
    }

    private var list: some View {
        List {
            ForEach(viewModel.favoritePlaces) { place in
                Button {
                    editingPlace = place
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
                .accessibilityIdentifier("favorite_places_row_\(place.id)")
                .accessibilityHint("Opens a form to edit this place")
            }
            .onDelete(perform: delete)
        }
        .listStyle(.plain)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            viewModel.remove(id: viewModel.favoritePlaces[index].id)
        }
    }
}

#if DEBUG
struct FavoritePlacesListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FavoritePlacesListView()
        }
        .navigationViewStyle(.stack)
        .environmentObject(AppSessionStore())
    }
}
#endif
