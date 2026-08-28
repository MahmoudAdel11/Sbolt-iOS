//
//  TripHistoryViewModel.swift
//  Yalla Go
//

import Foundation
import Combine

/// Drives the trip-history screen: loads, refreshes, and paginates trips via
/// the use case and publishes UI-facing state. Main-actor isolated for SwiftUI.
@MainActor
final class TripHistoryViewModel: ObservableObject {

    @Published private(set) var trips: [Trip] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = false
    @Published private(set) var errorMessage: String?
    /// `true` once a `.sessionExpired` error is caught. The view observes
    /// this and signs the session out — the ViewModel itself has no access
    /// to `AppSessionStore` (kept environment-agnostic, testable in isolation).
    @Published private(set) var isSessionExpired = false

    /// `true` when a successful load returned no trips.
    var isEmpty: Bool {
        !isLoading && errorMessage == nil && trips.isEmpty
    }

    private let getTripHistoryUseCase: GetTripHistoryUseCase
    private let errorPresenter: TripHistoryErrorPresenter
    /// Exposed read-only so callers/tests can await the in-flight operation.
    private(set) var activeTask: Task<Void, Never>?
    /// Exposed read-only so callers/tests can await an in-flight "load more".
    private(set) var loadMoreTask: Task<Void, Never>?

    init(getTripHistoryUseCase: GetTripHistoryUseCase,
         errorPresenter: TripHistoryErrorPresenter = TripHistoryErrorPresenter()) {
        self.getTripHistoryUseCase = getTripHistoryUseCase
        self.errorPresenter = errorPresenter
    }

    deinit {
        activeTask?.cancel()
        loadMoreTask?.cancel()
    }

    /// Loads the first page. Ignored while another operation is in flight.
    func loadTripHistory() {
        startLoad(refresh: false)
    }

    /// Forces a fresh load of the first page. Existing trips are kept if it fails.
    func refresh() {
        startLoad(refresh: true)
    }

    /// Loads the next page and appends it. Ignored unless a further page
    /// exists and no load is already in flight.
    func loadMore() {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        isLoadingMore = true
        let offset = trips.count
        loadMoreTask = Task { [weak self] in
            await self?.performLoadMore(offset: offset)
        }
    }

    /// Cancels any in-flight operation (e.g. when the screen disappears).
    func cancel() {
        activeTask?.cancel()
        loadMoreTask?.cancel()
    }

    private func startLoad(refresh: Bool) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        activeTask = Task { [weak self] in
            await self?.performLoad(refresh: refresh)
        }
    }

    private func performLoad(refresh: Bool) async {
        defer { isLoading = false }
        do {
            let page = try await getTripHistoryUseCase.execute(offset: 0, refresh: refresh)
            guard !Task.isCancelled else { return }
            trips = page.trips
            hasMore = page.hasMore
        } catch is CancellationError {
            // Cancelled: leave state untouched.
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = errorPresenter.message(for: error)
            if case TripHistoryError.sessionExpired = error { isSessionExpired = true }
        }
    }

    private func performLoadMore(offset: Int) async {
        defer { isLoadingMore = false }
        do {
            let page = try await getTripHistoryUseCase.execute(offset: offset, refresh: false)
            guard !Task.isCancelled else { return }
            // offset was captured before the await, so this appends exactly
            // the next page regardless of what else happened concurrently.
            trips += page.trips
            hasMore = page.hasMore
        } catch is CancellationError {
            // Cancelled: leave state untouched.
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = errorPresenter.message(for: error)
            if case TripHistoryError.sessionExpired = error { isSessionExpired = true }
        }
    }
}
