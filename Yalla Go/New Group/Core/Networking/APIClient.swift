
//
//  APIClient.swift
//  Yalla Go
//

import Foundation

// MARK: - Protocol

/// Sends a typed `Endpoint` and returns a decoded response.
/// The protocol boundary keeps ViewModels and use cases independent of URLSession,
/// so a test double can be substituted without modifying production code.
protocol APIClient {
    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

// MARK: - URLSession implementation

/// Production `APIClient` backed by `URLSession`.
///
/// Injecting a custom `URLSession` (e.g. one configured with `MockURLProtocol`)
/// lets unit tests intercept and verify requests without making real network calls.
final class URLSessionAPIClient: APIClient {

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = .backend
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.url(relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        #if DEBUG
        NetworkLogger.logRequest(request)
        let startTime = Date()
        #endif

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .cancelled:                                          throw NetworkError.requestCancelled
            case .timedOut:                                          throw NetworkError.timeout
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .dataNotAllowed:                                    throw NetworkError.noInternet
            default:                                                 throw NetworkError.unknown(urlError.localizedDescription)
            }
        } catch {
            throw NetworkError.unknown(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.unknown("Expected HTTPURLResponse, got \(type(of: response))")
        }

        #if DEBUG
        NetworkLogger.logResponse(http, data: data, duration: Date().timeIntervalSince(startTime))
        #endif

        switch http.statusCode {
        case 200...299: break
        case 401:       throw NetworkError.unauthorized
        case 403:       throw NetworkError.forbidden
        case 404:       throw NetworkError.notFound
        case 409:       throw NetworkError.conflict(errorCode: try? decoder.decode(BackendErrorBody.self, from: data).errorCode)
        default:
            let message = String(data: data, encoding: .utf8)
            throw NetworkError.serverError(statusCode: http.statusCode, message: message)
        }

        guard !data.isEmpty else {
            throw NetworkError.noData
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }
}

/// Shape of every backend error body (`{"error_code": ..., "message": ...}`,
/// per `app/api/error_handlers.py`), used only to pull `error_code` out for
/// `NetworkError.conflict(errorCode:)` — never surfaced beyond that.
private struct BackendErrorBody: Decodable {
    let errorCode: String
}
