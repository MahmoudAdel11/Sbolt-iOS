//
//  FavoritePlacesViewModel.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation
import Combine

/// Drives the (future) favourite-places screen: loads, adds, and removes saved
/// places via use cases and publishes UI-facing state. Main-actor isolated.
@MainActor
final class FavoritePlacesViewModel: ObservableObject {

    @Published private(set) var favoritePlaces: [FavoritePlace] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    /// `true` after the most recent add/remove succeeded. Reset when a new action starts.
    @Published private(set) var actionSucceeded = false

    /// `true` when a successful load returned no places.
    var isEmpty: Bool {
        !isLoading && errorMessage == nil && favoritePlaces.isEmpty
    }

    private let getFavoritePlacesUseCase: GetFavoritePlacesUseCase
    private let addFavoritePlaceUseCase: AddFavoritePlaceUseCase
    private let removeFavoritePlaceUseCase: RemoveFavoritePlaceUseCase
    private let errorPresenter: FavoritePlaceErrorPresenter
    /// Exposed read-only so callers/tests can await the in-flight operation.
    private(set) var activeTask: Task<Void, Never>?

    init(getFavoritePlacesUseCase: GetFavoritePlacesUseCase,
         addFavoritePlaceUseCase: AddFavoritePlaceUseCase,
         removeFavoritePlaceUseCase: RemoveFavoritePlaceUseCase,
         errorPresenter: FavoritePlaceErrorPresenter = FavoritePlaceErrorPresenter()) {
        self.getFavoritePlacesUseCase = getFavoritePlacesUseCase
        self.addFavoritePlaceUseCase = addFavoritePlaceUseCase
        self.removeFavoritePlaceUseCase = removeFavoritePlaceUseCase
        self.errorPresenter = errorPresenter
    }

    deinit {
        activeTask?.cancel()
    }

    /// Loads the favourites. Ignored while another operation is in flight.
    func loadFavorites() {
        run { try await self.getFavoritePlacesUseCase.execute() }
    }

    /// Reloads the favourites. Existing places are kept if the reload fails.
    func refresh() {
        loadFavorites()
    }

    /// Adds a place, then reflects the updated list.
    func add(_ place: FavoritePlace) {
        run(isAction: true) { try await self.addFavoritePlaceUseCase.execute(place) }
    }

    /// Removes a place by id, then reflects the updated list.
    func remove(id: String) {
        run(isAction: true) { try await self.removeFavoritePlaceUseCase.execute(id: id) }
    }

    /// Cancels an in-flight operation (e.g. when the screen disappears).
    func cancel() {
        activeTask?.cancel()
    }

    /// Runs an operation that yields the latest favourites, centralising the
    /// loading / cancellation / error handling shared by every action.
    private func run(isAction: Bool = false,
                     operation: @escaping () async throws -> [FavoritePlace]) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        if isAction { actionSucceeded = false }

        activeTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isLoading = false }
            do {
                let places = try await operation()
                guard !Task.isCancelled else { return }
                self.favoritePlaces = places
                if isAction { self.actionSucceeded = true }
            } catch is CancellationError {
                // Cancelled: leave state untouched.
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = self.errorPresenter.message(for: error)
            }
        }
    }
}
