//
//  RemoteDriverRepositoryTests.swift
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

private func userJSON(isOnline: Bool) -> Data {
    let json = """
    {
        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "email": "driver@yallago.com",
        "full_name": "Driver User",
        "phone_number": "+201234567890",
        "is_active": true,
        "driver_profile": {"is_online": \(isOnline)},
        "created_at": "2026-01-01T00:00:00.000000Z"
    }
    """
    return Data(json.utf8)
}

private func rideJSON(id: String = "ride-1", status: String = "requested") -> String {
    """
    {
        "id": "\(id)", "rider_id": "rider-1", "driver_id": null,
        "status": "\(status)", "tier": "economy", "fare": 15.0,
        "pickup_latitude": 30.05, "pickup_longitude": 31.23,
        "dropoff_latitude": 30.06, "dropoff_longitude": 31.24,
        "requested_at": "2026-01-01T00:00:00.000000Z",
        "accepted_at": null, "completed_at": null, "cancelled_at": null
    }
    """
}

struct RemoteDriverRepositoryTests {

    @Test func setOnlineStatusSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(userJSON(isOnline: true))
        let sut = RemoteDriverRepository(client: client)

        let user = try await sut.setOnlineStatus(true)

        #expect(user.driverProfile?.isOnline == true)
        #expect(client.capturedEndpoint?.path == "/drivers/me/status")
        #expect(client.capturedEndpoint?.method == .patch)
        let body = try #require(client.capturedEndpoint?.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["is_online"] as? Bool == true)
    }

    @Test func fetchAvailableRidesSendsLatLngAndDecodesArray() async throws {
        let client = StubAPIClient()
        client.result = .success(Data("[\(rideJSON(id: "ride-1")), \(rideJSON(id: "ride-2"))]".utf8))
        let sut = RemoteDriverRepository(client: client)

        let rides = try await sut.fetchAvailableRides(near: Coordinate(latitude: 30.05, longitude: 31.23))

        #expect(rides.count == 2)
        #expect(client.capturedEndpoint?.path == "/rides/available")
        #expect(client.capturedEndpoint?.queryItems.first { $0.name == "lat" }?.value == "30.05")
        #expect(client.capturedEndpoint?.queryItems.first { $0.name == "lng" }?.value == "31.23")
    }

    @Test func acceptRideSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(Data(rideJSON(id: "ride-1", status: "accepted").utf8))
        let sut = RemoteDriverRepository(client: client)

        let trip = try await sut.acceptRide(id: "ride-1")

        #expect(trip.status == .accepted)
        #expect(client.capturedEndpoint?.path == "/rides/ride-1/accept")
        #expect(client.capturedEndpoint?.method == .post)
    }

    @Test func acceptRideConflictMapsToRideNoLongerAvailable() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.conflict(errorCode: "conflict"))
        let sut = RemoteDriverRepository(client: client)

        await #expect(throws: DriverError.rideNoLongerAvailable) {
            _ = try await sut.acceptRide(id: "ride-1")
        }
    }

    @Test func acceptRideCancelledConflictMapsToRideCancelledByRider() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.conflict(errorCode: "ride_cancelled"))
        let sut = RemoteDriverRepository(client: client)

        await #expect(throws: DriverError.rideCancelledByRider) {
            _ = try await sut.acceptRide(id: "ride-1")
        }
    }

    @Test func acceptRideConflictWithNoErrorCodeMapsToRideNoLongerAvailable() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.conflict(errorCode: nil))
        let sut = RemoteDriverRepository(client: client)

        await #expect(throws: DriverError.rideNoLongerAvailable) {
            _ = try await sut.acceptRide(id: "ride-1")
        }
    }

    @Test func startRideSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(Data(rideJSON(id: "ride-1", status: "ongoing").utf8))
        let sut = RemoteDriverRepository(client: client)

        let trip = try await sut.startRide(id: "ride-1")

        #expect(trip.status == .ongoing)
        #expect(client.capturedEndpoint?.path == "/rides/ride-1/start")
        #expect(client.capturedEndpoint?.method == .post)
    }

    @Test func startRideConflictMapsToRideNotStartable() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.conflict(errorCode: "conflict"))
        let sut = RemoteDriverRepository(client: client)

        await #expect(throws: DriverError.rideNotStartable) {
            _ = try await sut.startRide(id: "ride-1")
        }
    }

    @Test func startRideCancelledConflictMapsToRideCancelledByRider() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.conflict(errorCode: "ride_cancelled"))
        let sut = RemoteDriverRepository(client: client)

        await #expect(throws: DriverError.rideCancelledByRider) {
            _ = try await sut.startRide(id: "ride-1")
        }
    }

    @Test func completeRideSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(Data(rideJSON(id: "ride-1", status: "completed").utf8))
        let sut = RemoteDriverRepository(client: client)

        let trip = try await sut.completeRide(id: "ride-1")

        #expect(trip.status == .completed)
        #expect(client.capturedEndpoint?.path == "/rides/ride-1/complete")
    }

    @Test func completeRideConflictMapsToRideNotCompletable() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.conflict(errorCode: "conflict"))
        let sut = RemoteDriverRepository(client: client)

        await #expect(throws: DriverError.rideNotCompletable) {
            _ = try await sut.completeRide(id: "ride-1")
        }
    }

    @Test func completeRideCancelledConflictMapsToRideCancelledByRider() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.conflict(errorCode: "ride_cancelled"))
        let sut = RemoteDriverRepository(client: client)

        await #expect(throws: DriverError.rideCancelledByRider) {
            _ = try await sut.completeRide(id: "ride-1")
        }
    }

    @Test func forbiddenMapsToNotAuthorizedAsDriver() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.forbidden)
        let sut = RemoteDriverRepository(client: client)

        await #expect(throws: DriverError.notAuthorizedAsDriver) {
            _ = try await sut.fetchAvailableRides(near: Coordinate(latitude: 0, longitude: 0))
        }
    }

    @Test func unauthorizedMapsToSessionExpired() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.unauthorized)
        let sut = RemoteDriverRepository(client: client)

        await #expect(throws: DriverError.sessionExpired) {
            _ = try await sut.setOnlineStatus(true)
        }
    }
}
