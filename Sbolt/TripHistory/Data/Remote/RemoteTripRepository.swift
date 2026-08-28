
//
//  RemoteTripRepository.swift
//  Yalla Go
//

import Foundation

/// `TripRepository` backed by the Yalla Go REST API.
final class RemoteTripRepository: TripRepository {

    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func fetchTripHistory(offset: Int, limit: Int, view: RideView) async throws -> TripHistoryPage {
        try await loadPage(offset: offset, limit: limit, view: view)
    }

    func refreshTripHistory(limit: Int, view: RideView) async throws -> TripHistoryPage {
        try await loadPage(offset: 0, limit: limit, view: view)
    }

    private func loadPage(offset: Int, limit: Int, view: RideView) async throws -> TripHistoryPage {
        do {
            let dto: RideDTO.RideHistoryResponse = try await client.send(
                Endpoint(
                    path: "/rides/history",
                    method: .get,
                    queryItems: [
                        URLQueryItem(name: "limit", value: String(limit)),
                        URLQueryItem(name: "offset", value: String(offset)),
                        URLQueryItem(name: "as", value: view.rawValue)
                    ]
                )
            )
            return TripHistoryPage(trips: dto.items.map { $0.toDomain() }, hasMore: dto.hasMore)
        } catch {
            throw mapped(error)
        }
    }

    // MARK: - Error mapping

    private func mapped(_ error: Error) -> TripHistoryError {
        if let historyError = error as? TripHistoryError { return historyError }
        switch error {
        case NetworkError.unauthorized:
            return .sessionExpired
        case NetworkError.noInternet, NetworkError.timeout:
            return .networkUnavailable
        default:
            return .historyUnavailable
        }
    }
}
