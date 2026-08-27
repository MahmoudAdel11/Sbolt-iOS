//
//  RemoteDriverRepository.swift
//  Yalla Go
//

import Foundation

/// `DriverRepository` backed by the Yalla Go REST API.
final class RemoteDriverRepository: DriverRepository {

    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func setOnlineStatus(_ isOnline: Bool) async throws -> User {
        do {
            let body = try JSONEncoder.backend.encode(DriverDTO.StatusUpdateRequest(isOnline: isOnline))
            let dto: AuthDTO.UserResponse = try await client.send(
                Endpoint(path: "/drivers/me/status", method: .patch, body: body)
            )
            return dto.toDomain()
        } catch {
            throw mapped(error)
        }
    }

    func fetchAvailableRides(near coordinate: Coordinate) async throws -> [Trip] {
        do {
            let dtos: [RideDTO.RideResponse] = try await client.send(
                Endpoint(
                    path: "/rides/available",
                    method: .get,
                    queryItems: [
                        URLQueryItem(name: "lat", value: String(coordinate.latitude)),
                        URLQueryItem(name: "lng", value: String(coordinate.longitude))
                    ]
                )
            )
            return dtos.map { $0.toDomain() }
        } catch {
            throw mapped(error)
        }
    }

    func acceptRide(id: String) async throws -> Trip {
        do {
            let dto: RideDTO.RideResponse = try await client.send(
                Endpoint(path: "/rides/\(id)/accept", method: .post)
            )
            return dto.toDomain()
        } catch {
            throw mapped(error, conflict: .rideNoLongerAvailable)
        }
    }

    func startRide(id: String) async throws -> Trip {
        do {
            let dto: RideDTO.RideResponse = try await client.send(
                Endpoint(path: "/rides/\(id)/start", method: .post)
            )
            return dto.toDomain()
        } catch {
            throw mapped(error, conflict: .rideNotStartable)
        }
    }

    func completeRide(id: String) async throws -> Trip {
        do {
            let dto: RideDTO.RideResponse = try await client.send(
                Endpoint(path: "/rides/\(id)/complete", method: .post)
            )
            return dto.toDomain()
        } catch {
            throw mapped(error, conflict: .rideNotCompletable)
        }
    }

    func updateVehicle(
        vehicleType: String?, vehicleColor: String?, licensePlate: String?, scooterType: RideType?
    ) async throws -> User {
        do {
            let body = try JSONEncoder.backend.encode(
                DriverDTO.VehicleUpdateRequest(
                    vehicleType: vehicleType,
                    vehicleColor: vehicleColor,
                    licensePlate: licensePlate,
                    scooterType: scooterType?.rawValue
                )
            )
            let dto: AuthDTO.UserResponse = try await client.send(
                Endpoint(path: "/drivers/me/vehicle", method: .patch, body: body)
            )
            return dto.toDomain()
        } catch {
            throw mapped(error)
        }
    }

    // MARK: - Error mapping

    private func mapped(_ error: Error, conflict: DriverError = .unknown) -> DriverError {
        if let driverError = error as? DriverError { return driverError }
        switch error {
        case NetworkError.unauthorized:
            return .sessionExpired
        case NetworkError.forbidden:
            return .notAuthorizedAsDriver
        case NetworkError.notFound:
            return .rideNotFound
        case NetworkError.conflict(let errorCode):
            switch errorCode {
            case "ride_cancelled":   return .rideCancelledByRider
            case "ride_not_started": return .rideNotStarted
            default:                 return conflict
            }
        case NetworkError.noInternet, NetworkError.timeout:
            return .networkUnavailable
        default:
            return .unknown
        }
    }
}
