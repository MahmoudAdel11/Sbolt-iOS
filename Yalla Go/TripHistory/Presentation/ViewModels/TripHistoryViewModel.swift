//
//  TripHistoryViewModel.swift
//  Yalla Go
//
//  Created by Mahmoud on 29/07/2026.
//

import Foundation
import Combine

/// Drives the (future) trip-history screen: loads and refreshes completed trips
/// via the use case and publishes UI-facing state. Main-actor isolated for SwiftUI.
@MainActor
final class TripHistoryViewModel: ObservableObject {

    @Published private(set) var trips: [Trip] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    /// `true` when a successful load returned no trips.
    var isEmpty: Bool {
        !isLoading && errorMessage == nil && trips.isEmpty
    }

    private let getTripHistoryUseCase: GetTripHistoryUseCase
    private let errorPresenter: TripHistoryErrorPresenter
    /// Exposed read-only so callers/tests can await the in-flight operation.
    private(set) var activeTask: Task<Void, Never>?

    init(getTripHistoryUseCase: GetTripHistoryUseCase,
         errorPresenter: TripHistoryErrorPresenter = TripHistoryErrorPresenter()) {
        self.getTripHistoryUseCase = getTripHistoryUseCase
        self.errorPresenter = errorPresenter
    }

    deinit {
        activeTask?.cancel()
    }

    /// Loads the trip history. Ignored while another operation is in flight.
    func loadTripHistory() {
        startLoad(refresh: false)
    }

    /// Forces a fresh load. Existing trips are kept if the refresh fails.
    func refresh() {
        startLoad(refresh: true)
    }

    /// Cancels an in-flight operation (e.g. when the screen disappears).
    func cancel() {
        activeTask?.cancel()
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
            let trips = try await getTripHistoryUseCase.execute(refresh: refresh)
            guard !Task.isCancelled else { return }
            self.trips = trips
        } catch is CancellationError {
            // Cancelled: leave state untouched.
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = errorPresenter.message(for: error)
        }
    }
}
