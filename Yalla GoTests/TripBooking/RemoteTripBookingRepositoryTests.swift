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

private func rideJSON(id: String = "ride-1", status: String = "requested", driverId: String? = nil,
                      driverSummaryJSON: String = "null", tier: String = "economy", fare: Double = 15.0,
                      pickupAddress: String? = nil, dropoffAddress: String? = nil) -> Data {
    let driverField = driverId.map { "\"\($0)\"" } ?? "null"
    let pickupAddressField = pickupAddress.map { "\"\($0)\"" } ?? "null"
    let dropoffAddressField = dropoffAddress.map { "\"\($0)\"" } ?? "null"
    let json = """
    {
        "id": "\(id)", "rider_id": "rider-1", "driver_id": \(driverField),
        "driver": \(driverSummaryJSON),
        "status": "\(status)", "tier": "\(tier)", "fare": \(fare),
        "pickup_latitude": 30.05, "pickup_longitude": 31.23,
        "dropoff_latitude": 30.06, "dropoff_longitude": 31.24,
        "pickup_address": \(pickupAddressField), "dropoff_address": \(dropoffAddressField),
        "requested_at": "2026-01-01T00:00:00.000000Z",
        "accepted_at": null, "completed_at": null, "cancelled_at": null
    }
    """
    return Data(json.utf8)
}

private let sampleDriverSummaryJSON = """
{
    "name": "Jane Driver",
    "vehicle_type": "Sedan",
    "vehicle_color": "White",
    "license_plate": "ABC-123",
    "average_rating": 4.8,
    "rating_count": 12
}
"""

struct RemoteTripBookingRepositoryTests {

    private let pickup = Coordinate(latitude: 30.05, longitude: 31.23)
    private let dropoff = Coordinate(latitude: 30.06, longitude: 31.24)

    @Test func requestRideSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(rideJSON())
        let sut = RemoteTripBookingRepository(client: client)

        let trip = try await sut.requestRide(pickup: pickup, dropoff: dropoff, tier: .economy)

        #expect(trip.status == .requested)
        #expect(client.capturedEndpoint?.path == "/rides")
        #expect(client.capturedEndpoint?.method == .post)

        let body = try #require(client.capturedEndpoint?.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["pickup_latitude"] as? Double == 30.05)
        #expect(json["dropoff_longitude"] as? Double == 31.24)
    }

    @Test func requestRideSendsSelectedTierAndDecodesRealFare() async throws {
        let client = StubAPIClient()
        client.result = .success(rideJSON(tier: "premium", fare: 40.0))
        let sut = RemoteTripBookingRepository(client: client)

        let trip = try await sut.requestRide(pickup: pickup, dropoff: dropoff, tier: .premium)

        let body = try #require(client.capturedEndpoint?.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["tier"] as? String == "premium")

        #expect(trip.tier == .premium)
        #expect(trip.fare == 40.0)
    }

    @Test func requestRideSendsResolvedAddressesInRequestBody() async throws {
        let client = StubAPIClient()
        client.result = .success(rideJSON())
        let sut = RemoteTripBookingRepository(client: client)

        _ = try await sut.requestRide(
            pickup: pickup, dropoff: dropoff, tier: .economy,
            pickupAddress: "New Cairo", dropoffAddress: "Downtown Cairo"
        )

        let body = try #require(client.capturedEndpoint?.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["pickup_address"] as? String == "New Cairo")
        #expect(json["dropoff_address"] as? String == "Downtown Cairo")
    }

    /// Per the confirmed decision, a failed/unavailable geocoding lookup must
    /// still let the ride be created — nil addresses either encode as JSON
    /// `null` or are omitted entirely (both mean "no address" to the
    /// backend's optional, defaulted `RideRequestSchema` fields); either way
    /// the request body must never contain a non-null placeholder string.
    @Test func requestRideSendsNilAddressesWhenGeocodingFailed() async throws {
        let client = StubAPIClient()
        client.result = .success(rideJSON())
        let sut = RemoteTripBookingRepository(client: client)

        _ = try await sut.requestRide(
            pickup: pickup, dropoff: dropoff, tier: .economy,
            pickupAddress: nil, dropoffAddress: nil
        )

        let body = try #require(client.capturedEndpoint?.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let pickupAddress = json["pickup_address"]
        let dropoffAddress = json["dropoff_address"]
        #expect(pickupAddress == nil || pickupAddress is NSNull)
        #expect(dropoffAddress == nil || dropoffAddress is NSNull)
    }

    @Test func requestRideDecodesResolvedAddressesFromResponse() async throws {
        let client = StubAPIClient()
        client.result = .success(rideJSON(pickupAddress: "New Cairo", dropoffAddress: "Downtown Cairo"))
        let sut = RemoteTripBookingRepository(client: client)

        let trip = try await sut.requestRide(pickup: pickup, dropoff: dropoff, tier: .economy)

        #expect(trip.pickupAddress == "New Cairo")
        #expect(trip.dropoffAddress == "Downtown Cairo")
    }

    @Test func requestRideDecodesNilAddressesWhenBackendHasNone() async throws {
        let client = StubAPIClient()
        client.result = .success(rideJSON())
        let sut = RemoteTripBookingRepository(client: client)

        let trip = try await sut.requestRide(pickup: pickup, dropoff: dropoff, tier: .economy)

        #expect(trip.pickupAddress == nil)
        #expect(trip.dropoffAddress == nil)
    }

    @Test func requestRideMapsConflictToActiveRideAlreadyExists() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.conflict(errorCode: nil))
        let sut = RemoteTripBookingRepository(client: client)

        await #expect(throws: RideError.activeRideAlreadyExists) {
            _ = try await sut.requestRide(pickup: pickup, dropoff: dropoff, tier: .economy)
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

    @Test func getRideDetailsHasNilDriverWhenNoneAssigned() async throws {
        let client = StubAPIClient()
        client.result = .success(rideJSON(status: "requested", driverId: nil))
        let sut = RemoteTripBookingRepository(client: client)

        let trip = try await sut.getRideDetails(id: "ride-1")

        #expect(trip.driverID == nil)
        #expect(trip.driver == nil)
    }

    @Test func getRideDetailsDecodesEmbeddedDriverSummary() async throws {
        let client = StubAPIClient()
        client.result = .success(
            rideJSON(status: "accepted", driverId: "driver-9", driverSummaryJSON: sampleDriverSummaryJSON)
        )
        let sut = RemoteTripBookingRepository(client: client)

        let trip = try await sut.getRideDetails(id: "ride-1")

        let driver = try #require(trip.driver)
        #expect(driver.id == "driver-9")
        #expect(driver.name == "Jane Driver")
        #expect(driver.vehicleName == "Sedan")
        #expect(driver.vehicleColor == "White")
        #expect(driver.plateNumber == "ABC-123")
        #expect(driver.rating == 4.8)
        #expect(driver.ratingCount == 12)
    }

    @Test func submitRatingSendsScoreAndSucceeds() async throws {
        let client = StubAPIClient()
        client.result = .success(Data("""
        {
            "id": "rating-1", "ride_id": "ride-1", "rider_id": "rider-1",
            "driver_id": "driver-9", "score": 5, "created_at": "2026-01-01T00:00:00.000000Z"
        }
        """.utf8))
        let sut = RemoteTripBookingRepository(client: client)

        try await sut.submitRating(rideID: "ride-1", score: 5)

        #expect(client.capturedEndpoint?.path == "/rides/ride-1/rating")
        #expect(client.capturedEndpoint?.method == .post)
        let body = try #require(client.capturedEndpoint?.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["score"] as? Int == 5)
    }

    @Test func submitRatingMapsConflictToRatingFailed() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.conflict(errorCode: nil))
        let sut = RemoteTripBookingRepository(client: client)

        await #expect(throws: RideError.ratingFailed) {
            try await sut.submitRating(rideID: "ride-1", score: 5)
        }
    }

    @Test func submitRatingMapsUnauthorizedToSessionExpired() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.unauthorized)
        let sut = RemoteTripBookingRepository(client: client)

        await #expect(throws: RideError.sessionExpired) {
            try await sut.submitRating(rideID: "ride-1", score: 5)
        }
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

    @Test func getActiveRideReturnsTripWhenOneExists() async throws {
        let client = StubAPIClient()
        client.result = .success(rideJSON(status: "accepted", driverId: "driver-9"))
        let sut = RemoteTripBookingRepository(client: client)

        let trip = try await sut.getActiveRide()

        #expect(trip?.status == .accepted)
        #expect(client.capturedEndpoint?.path == "/rides/active")
        #expect(client.capturedEndpoint?.method == .get)
    }

    @Test func getActiveRideReturnsNilOnNullBody() async throws {
        let client = StubAPIClient()
        // Backend returns 200 with a literal JSON `null` body when the rider
        // has no active ride - not an error, not an empty body.
        client.result = .success(Data("null".utf8))
        let sut = RemoteTripBookingRepository(client: client)

        let trip = try await sut.getActiveRide()

        #expect(trip == nil)
    }

    @Test func getActiveRideMapsUnauthorizedToSessionExpired() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.unauthorized)
        let sut = RemoteTripBookingRepository(client: client)

        await #expect(throws: RideError.sessionExpired) {
            _ = try await sut.getActiveRide()
        }
    }

    @Test func unauthorizedMapsToSessionExpiredOnAllCalls() async {
        let client = StubAPIClient()
        client.result = .failure(NetworkError.unauthorized)
        let sut = RemoteTripBookingRepository(client: client)

        await #expect(throws: RideError.sessionExpired) {
            _ = try await sut.requestRide(pickup: pickup, dropoff: dropoff, tier: .economy)
        }
        await #expect(throws: RideError.sessionExpired) {
            _ = try await sut.cancelRide(id: "ride-1")
        }
        await #expect(throws: RideError.sessionExpired) {
            _ = try await sut.getRideDetails(id: "ride-1")
        }
    }
}
