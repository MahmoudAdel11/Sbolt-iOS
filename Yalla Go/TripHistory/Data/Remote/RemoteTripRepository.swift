
//
//  RemoteTripRepository.swift
//  Yalla Go
//

import Foundation

/// `TripRepository` backed by the Yalla Go REST API.
///
/// Stubs out as `NetworkError.serverError(statusCode: 501, ...)` until
/// the endpoint is wired and the DTO → domain mapping is filled in.
final class RemoteTripRepository: TripRepository {

    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func fetchTripHistory() async throws -> [Trip] {
        // TODO: let dtos: [TripDTO.TripResponse] = try await client.send(.tripHistory)
        // TODO: return dtos.map { $0.toDomain() }
        throw NetworkError.serverError(statusCode: 501, message: "Remote trip history not yet connected")
    }

    func refreshTripHistory() async throws -> [Trip] {
        try await fetchTripHistory()
    }
}
