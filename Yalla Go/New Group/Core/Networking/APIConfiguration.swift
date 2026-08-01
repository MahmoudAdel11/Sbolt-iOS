
//
//  APIConfiguration.swift
//  Yalla Go
//

import Foundation

/// Static backend configuration.
/// Replace `baseURLString` with the real server URL before enabling
/// `RemoteRepositoryFactory` in production.
enum APIConfiguration {
    private static let baseURLString = "https://api.yallago.com/v1"

    static var baseURL: URL {
        guard let url = URL(string: baseURLString) else {
            preconditionFailure("APIConfiguration.baseURLString is not a valid URL — check for typos")
        }
        return url
    }
}
