
//
//  NetworkError.swift
//  Yalla Go
//

/// Errors produced by the networking layer. Maps raw URLSession and HTTP
/// failures into a closed, equatable set so callers can pattern-match on
/// specific cases without parsing strings.
enum NetworkError: Error, Equatable {
    /// The Endpoint produced a path that URLComponents could not resolve.
    case invalidURL
    /// A 2xx response contained an empty body where data was expected.
    case noData
    /// JSON decoding failed — the schema did not match the response body.
    case decodingFailed(String)
    /// The server replied with a non-2xx status code not covered by a specific case.
    case serverError(statusCode: Int, message: String?)
    /// The server returned 401 Unauthorized.
    case unauthorized
    /// The server returned 403 Forbidden.
    case forbidden
    /// The server returned 404 Not Found.
    case notFound
    /// The server returned 409 Conflict.
    case conflict
    /// The request exceeded the allowed time limit.
    case timeout
    /// The device has no active internet connection.
    case noInternet
    /// The in-flight Task was cancelled by the caller.
    case requestCancelled
    /// Any other failure not covered by the cases above.
    case unknown(String)
}
