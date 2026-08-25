//
//  RemoteTripRepositoryTests.swift
//  Yalla GoTests
//

import Testing
import Foundation
@testable import Yalla_Go

private final class StubAPIClient: APIClient {
    enum StubResult {
        case success(Data)
        case failure(Error)
    }

    var result: StubResult = .failure(NetworkError.unknown("unset"))
    private(set) var capturedEndpoint: Endpoint?

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        capturedEndpoint = endpoint
        switch result {
        case .success(let data):
            return try JSONDecoder.backend.decode(T.self, from: data)
        case .failure(let error):
            throw error
        }
    }
}

private func historyJSON(hasMore: Bool = false) -> Data {
    let json = """
    {
        "items": [
            {
                "id": "ride-1", "rider_id": "rider-1", "driver_id": null,
                "status": "requested", "tier": "economy", "fare": 15.0,
                "pickup_latitude": 30.05, "pickup_longitude": 31.23,
                "dropoff_latitude": 30.06, "dropoff_longitude": 31.24,
                "requested_at": "2026-01-01T00:00:00.000000Z",
                "accepted_at": null, "completed_at": null, "cancelled_at": null
            },
            {
                "id": "ride-2", "rider_id": "rider-1", "driver_id": "driver-2",
                "status": "completed", "tier": "premium", "fare": 78.0,
                "pickup_latitude": 30.01, "pickup_longitude": 31.20,
                "dropoff_latitude": 30.02, "dropoff_longitude": 31.21,
                "requested_at": "2026-01-01T00:00:00.000000Z",
                "accepted_at": "2026-01-01T00:01:00.000000Z",
                "completed_at": "2026-01-01T00:20:00.000000Z", "cancelled_at": null
            }
        ],
        "has_more": \(hasMore)
    }
    """
    return Data(json.utf8)
}

struct RemoteTripRepositoryTests {

    @Test func fetchTripHistorySucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(historyJSON())
        let sut = RemoteTripRepository(client: client)

        let page = try await sut.fetchTripHistory(offset: 0, limit: 20, view: .rider)

        #expect(page.trips.count == 2)
        #expect(page.trips[0].status == .requested)
        #expect(page.trips[1].status == .completed)
        #expect(page.trips[1].driverID == "driver-2")
        #expect(page.hasMore == false)
        #expect(client.capturedEndpoint?.path == "/rides/history")
        #expect(client.capturedEndpoint?.method == .get)
        #expect(client.capturedEndpoint?.queryItems.first { $0.name == "limit" }?.value == "20")
        #expect(client.capturedEndpoint?.queryItems.first { $0.name == "offset" }?.value == "0")
        #expect(client.capturedEndpoint?.queryItems.first { $0.name == "as" }?.value == "rider")
    }

    @Test func fetchTripHistoryForwardsOffsetAndHasMore() async throws {
        let client = StubAPIClient()
        client.result = .success(historyJSON(hasMore: true))
        let sut = RemoteTripRepository(client: client)

        let page = try await sut.fetchTripHistory(offset: 20, limit: 20, view: .rider)

        #expect(page.hasMore == true)
        #expect(client.capturedEndpoint?.queryItems.first { $0.name == "offset" }?.value == "20")
    }

    @Test func fetchTripHistoryForwardsDriverView() async throws {
        let client = StubAPIClient()
        client.result = .success(historyJSON())
        let sut = RemoteTripRepository(client: client)

        _ = try await sut.fetchTripHistory(offset: 0, limit: 20, view: .driver)

        #expect(client.capturedEndpoint?.queryItems.first { $0.name == "as" }?.value == "driver")
    }

    @Test func refreshTripHistoryAlwaysUsesOffsetZero() async throws {
        let client = StubAPIClient()
        client.result = .success(historyJSON())
        let sut = RemoteTripRepository(client: client)

        let page = try await sut.refreshTripHistory(limit: 20, view: .rider)

        #expect(page.trips.count == 2)
        #expect(client.capturedEndpoint?.queryItems.first { $0.name == "offset" }?.value == "0")
    }

    @Test func failureMapsToHistoryUnavailable() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.forbidden)
        let sut = RemoteTripRepository(client: client)

        await #expect(throws: TripHistoryError.historyUnavailable) {
            _ = try await sut.fetchTripHistory(offset: 0, limit: 20, view: .rider)
        }
    }

    @Test func unauthorizedMapsToSessionExpired() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.unauthorized)
        let sut = RemoteTripRepository(client: client)

        await #expect(throws: TripHistoryError.sessionExpired) {
            _ = try await sut.fetchTripHistory(offset: 0, limit: 20, view: .rider)
        }
    }

    @Test func networkFailureMapsToNetworkUnavailable() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.timeout)
        let sut = RemoteTripRepository(client: client)

        await #expect(throws: TripHistoryError.networkUnavailable) {
            _ = try await sut.fetchTripHistory(offset: 0, limit: 20, view: .rider)
        }
    }
}
