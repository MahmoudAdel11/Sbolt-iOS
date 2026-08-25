//
//  RemoteTripBookingRepository.swift
//  Yalla Go
//

import Foundation

/// `TripBookingRepository` backed by the Yalla Go REST API.
final class RemoteTripBookingRepository: TripBookingRepository {

    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func requestRide(pickup: Coordinate, dropoff: Coordinate, tier: RideType) async throws -> Trip {
        do {
            let body = try JSONEncoder.backend.encode(
                RideDTO.RideRequest(
                    pickupLatitude: pickup.latitude,
                    pickupLongitude: pickup.longitude,
                    dropoffLatitude: dropoff.latitude,
                    dropoffLongitude: dropoff.longitude,
                    tier: tier.rawValue
                )
            )
            let dto: RideDTO.RideResponse = try await client.send(
                Endpoint(path: "/rides", method: .post, body: body)
            )
            return dto.toDomain()
        } catch {
            throw mapped(error, conflict: .activeRideAlreadyExists)
        }
    }

    func cancelRide(id: String) async throws -> Trip {
        do {
            let dto: RideDTO.RideResponse = try await client.send(
                Endpoint(path: "/rides/\(id)/cancel", method: .post)
            )
            return dto.toDomain()
        } catch {
            throw mapped(error, conflict: .cancellationFailed)
        }
    }

    func getRideDetails(id: String) async throws -> Trip {
        do {
            let dto: RideDTO.RideResponse = try await client.send(
                Endpoint(path: "/rides/\(id)", method: .get)
            )
            return dto.toDomain()
        } catch {
            throw mapped(error, conflict: .unknown)
        }
    }

    func submitRating(rideID: String, score: Int) async throws {
        do {
            let body = try JSONEncoder.backend.encode(RatingDTO.RatingRequest(score: score))
            let _: RatingDTO.RatingResponse = try await client.send(
                Endpoint(path: "/rides/\(rideID)/rating", method: .post, body: body)
            )
        } catch {
            throw mapped(error, conflict: .ratingFailed)
        }
    }

    // MARK: - Error mapping

    private func mapped(_ error: Error, conflict: RideError) -> RideError {
        if let rideError = error as? RideError { return rideError }
        switch error {
        case NetworkError.unauthorized:
            return .sessionExpired
        case NetworkError.notFound:
            return .rideNotFound
        case NetworkError.forbidden:
            return .notPartOfRide
        case NetworkError.conflict:
            return conflict
        case NetworkError.noInternet, NetworkError.timeout:
            return .networkUnavailable
        default:
            return .unknown
        }
    }
}
