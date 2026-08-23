//
//  RemoteTripBookingRepositoryTests.swift
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

private func rideJSON(id: String = "ride-1", status: String = "requested", driverId: String? = nil) -> Data {
    let driverField = driverId.map { "\"\($0)\"" } ?? "null"
    let json = """
    {
        "id": "\(id)", "rider_id": "rider-1", "driver_id": \(driverField),
        "status": "\(status)",
        "pickup_latitude": 30.05, "pickup_longitude": 31.23,
        "dropoff_latitude": 30.06, "dropoff_longitude": 31.24,
        "requested_at": "2026-01-01T00:00:00.000000Z",
        "accepted_at": null, "completed_at": null, "cancelled_at": null
    }
    """
    return Data(json.utf8)
}

struct RemoteTripBookingRepositoryTests {

    private let pickup = Coordinate(latitude: 30.05, longitude: 31.23)
    private let dropoff = Coordinate(latitude: 30.06, longitude: 31.24)

    @Test func requestRideSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(rideJSON())
        let sut = RemoteTripBookingRepository(client: client)

        let trip = try await sut.requestRide(pickup: pickup, dropoff: dropoff)

        #expect(trip.status == .requested)
        #expect(client.capturedEndpoint?.path == "/rides")
        #expect(client.capturedEndpoint?.method == .post)

        let body = try #require(client.capturedEndpoint?.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["pickup_latitude"] as? Double == 30.05)
        #expect(json["dropoff_longitude"] as? Double == 31.24)
    }

    @Test func requestRideMapsConflictToActiveRideAlreadyExists() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.conflict(errorCode: nil))
        let sut = RemoteTripBookingRepository(client: client)

        await #expect(throws: RideError.activeRideAlreadyExists) {
            _ = try await sut.requestRide(pickup: pickup, dropoff: dropoff)
        }
    }

    @Test func cancelRideSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(rideJSON(status: "cancelled"))
        let sut = RemoteTripBookingRepository(client: client)

        let trip = try await sut.cancelRide(id: "ride-1")

        #expect(trip.status == .cancelled)
        #expect(client.capturedEndpoint?.path == "/rides/ride-1/cancel")
        #expect(client.capturedEndpoint?.method == .post)
    }

    @Test func cancelRideMapsConflictToCancellationFailed() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.conflict(errorCode: nil))
        let sut = RemoteTripBookingRepository(client: client)

        await #expect(throws: RideError.cancellationFailed) {
            _ = try await sut.cancelRide(id: "ride-1")
        }
    }

    @Test func getRideDetailsSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(rideJSON(status: "accepted", driverId: "driver-9"))
        let sut = RemoteTripBookingRepository(client: client)

        let trip = try await sut.getRideDetails(id: "ride-1")

        #expect(trip.status == .accepted)
        #expect(trip.driverID == "driver-9")
        #expect(client.capturedEndpoint?.path == "/rides/ride-1")
        #expect(client.capturedEndpoint?.method == .get)
    }

    @Test func getRideDetailsMapsNotFound() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.notFound)
        let sut = RemoteTripBookingRepository(client: client)

        await #expect(throws: RideError.rideNotFound) {
            _ = try await sut.getRideDetails(id: "missing")
        }
    }

    @Test func getRideDetailsMapsForbidden() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.forbidden)
        let sut = RemoteTripBookingRepository(client: client)

        await #expect(throws: RideError.notPartOfRide) {
            _ = try await sut.getRideDetails(id: "ride-1")
        }
    }

    @Test func networkFailureMapsToNetworkUnavailable() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.noInternet)
        let sut = RemoteTripBookingRepository(client: client)

        await #expect(throws: RideError.networkUnavailable) {
            _ = try await sut.getRideDetails(id: "ride-1")
        }
    }

    @Test func unauthorizedMapsToSessionExpiredOnAllCalls() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.unauthorized)
        let sut = RemoteTripBookingRepository(client: client)

        await #expect(throws: RideError.sessionExpired) {
            _ = try await sut.requestRide(pickup: pickup, dropoff: dropoff)
        }
        await #expect(throws: RideError.sessionExpired) {
            _ = try await sut.cancelRide(id: "ride-1")
        }
        await #expect(throws: RideError.sessionExpired) {
            _ = try await sut.getRideDetails(id: "ride-1")
        }
    }
}
