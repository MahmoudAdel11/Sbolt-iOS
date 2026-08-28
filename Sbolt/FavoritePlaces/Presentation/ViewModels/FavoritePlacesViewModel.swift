//
//  FavoritePlacesViewModel.swift
//  Yalla Go
//

import Foundation
import Combine

/// Drives the favourite-places screen: loads favourites via a use case and
/// publishes UI-facing state. Add/update/remove mutate the local array
/// in place (insert/replace/remove by id) using the single affected object
/// each use case returns — never a full re-fetch after a mutation.
@MainActor
final class FavoritePlacesViewModel: ObservableObject {

    @Published private(set) var favoritePlaces: [FavoritePlace] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    /// `true` after the most recent add/update/remove succeeded. Reset when a new action starts.
    @Published private(set) var actionSucceeded = false
    /// `true` once a `.sessionExpired` error is caught. The view observes
    /// this and signs the session out — the ViewModel itself has no access
    /// to `AppSessionStore` (kept environment-agnostic, testable in isolation).
    @Published private(set) var isSessionExpired = false

    /// `true` when a successful load returned no places.
    var isEmpty: Bool {
        !isLoading && errorMessage == nil && favoritePlaces.isEmpty
    }

    private let getFavoritePlacesUseCase: GetFavoritePlacesUseCase
    private let addFavoritePlaceUseCase: AddFavoritePlaceUseCase
    private let updateFavoritePlaceUseCase: UpdateFavoritePlaceUseCase
    private let removeFavoritePlaceUseCase: RemoveFavoritePlaceUseCase
    private let errorPresenter: FavoritePlaceErrorPresenter
    /// Exposed read-only so callers/tests can await the in-flight operation.
    private(set) var activeTask: Task<Void, Never>?

    init(getFavoritePlacesUseCase: GetFavoritePlacesUseCase,
         addFavoritePlaceUseCase: AddFavoritePlaceUseCase,
         updateFavoritePlaceUseCase: UpdateFavoritePlaceUseCase,
         removeFavoritePlaceUseCase: RemoveFavoritePlaceUseCase,
         errorPresenter: FavoritePlaceErrorPresenter = FavoritePlaceErrorPresenter()) {
        self.getFavoritePlacesUseCase = getFavoritePlacesUseCase
        self.addFavoritePlaceUseCase = addFavoritePlaceUseCase
        self.updateFavoritePlaceUseCase = updateFavoritePlaceUseCase
        self.removeFavoritePlaceUseCase = removeFavoritePlaceUseCase
        self.errorPresenter = errorPresenter
    }

    deinit {
        activeTask?.cancel()
    }

    /// Loads the favourites. Ignored while another operation is in flight.
    func loadFavorites() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        activeTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    /// Reloads the favourites. Existing places are kept if the reload fails.
    func refresh() {
        loadFavorites()
    }

    /// Adds a place, then inserts it into the local list.
    func add(_ place: FavoritePlace) {
        performAction { [weak self] in
            let created = try await self?.addFavoritePlaceUseCase.execute(place)
            if let created { self?.favoritePlaces.append(created) }
        }
    }

    /// Updates a place, then replaces it in the local list.
    func update(id: String, _ place: FavoritePlace) {
        performAction { [weak self] in
            let updated = try await self?.updateFavoritePlaceUseCase.execute(id: id, place)
            guard let self, let updated else { return }
            if let index = self.favoritePlaces.firstIndex(where: { $0.id == id }) {
                self.favoritePlaces[index] = updated
            }
        }
    }

    /// Removes a place by id, then removes it from the local list.
    func remove(id: String) {
        performAction { [weak self] in
            try await self?.removeFavoritePlaceUseCase.execute(id: id)
            self?.favoritePlaces.removeAll { $0.id == id }
        }
    }

    /// Cancels an in-flight operation (e.g. when the screen disappears).
    func cancel() {
        activeTask?.cancel()
    }

    private func performLoad() async {
        defer { isLoading = false }
        do {
            let places = try await getFavoritePlacesUseCase.execute()
            guard !Task.isCancelled else { return }
            favoritePlaces = places
        } catch is CancellationError {
            // Cancelled: leave state untouched.
        } catch {
            guard !Task.isCancelled else { return }
            handle(error)
        }
    }

    /// Runs a mutating action (add/update/remove), centralising the
    /// loading / cancellation / error handling shared by every action.
    private func performAction(_ operation: @escaping () async throws -> Void) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        actionSucceeded = false

        activeTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isLoading = false }
            do {
                try await operation()
                guard !Task.isCancelled else { return }
                self.actionSucceeded = true
            } catch is CancellationError {
                // Cancelled: leave state untouched.
            } catch {
                guard !Task.isCancelled else { return }
                self.handle(error)
            }
        }
    }

    private func handle(_ error: Error) {
        errorMessage = errorPresenter.message(for: error)
        if case FavoritePlaceError.sessionExpired = error { isSessionExpired = true }
    }
}
