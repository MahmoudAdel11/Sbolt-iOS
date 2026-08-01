
//
//  Endpoint.swift
//  Yalla Go
//

import Foundation

/// A complete description of one HTTP request, decoupled from any base URL
/// so the same value can be used with different environments (staging, production, test).
struct Endpoint {
    let path: String
    let method: HTTPMethod
    var headers: [String: String]
    var queryItems: [URLQueryItem]
    var body: Data?

    init(
        path: String,
        method: HTTPMethod,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
    }

    /// Resolves the endpoint's path against `baseURL` and appends any query items.
    ///
    /// Leading slashes are stripped before appending so both "/auth/login" and
    /// "auth/login" produce the same URL relative to the base — avoiding a
    /// double-slash when the base URL already ends with a path segment.
    func url(relativeTo baseURL: URL) -> URL? {
        let normalized = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var components = URLComponents(
            url: baseURL.appendingPathComponent(normalized),
            resolvingAgainstBaseURL: true
        )
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }
}
