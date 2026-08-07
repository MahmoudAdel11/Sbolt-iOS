//
//  EmptyResponse.swift
//  Yalla Go
//

import Foundation

/// Sentinel `Decodable` type for endpoints that return 204 No Content.
///
/// Usage — in a repository method:
/// ```swift
/// do {
///     let _: EmptyResponse = try await client.send(endpoint)
/// } catch NetworkError.noData {
///     // 204 received — treat as success
/// }
/// ```
struct EmptyResponse: Decodable {}
