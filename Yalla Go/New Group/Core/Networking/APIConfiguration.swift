
//
//  APIConfiguration.swift
//  Yalla Go
//

import Foundation

/// Identifies the target server environment.
/// Change `APIConfiguration.environment` to retarget the entire app — no
/// business code (use cases, view models, repositories) needs to change.
enum APIEnvironment {
    case development
    case staging
    case production

    var baseURLString: String {
        switch self {
        // Plain HTTP, local backend — the Debug-only ATS exception in
        // Yalla-Go-Info-Debug.plist exists specifically for this host.
        // Never used in Release builds (see that plist's build-setting wiring).
        case .development: return "http://localhost:8000/api/v1"
        case .staging:     return "https://staging-api.yallago.com/api/v1"
        case .production:  return "https://api.yallago.com/api/v1"
        }
    }
}

/// Static backend configuration.
/// To switch environments change exactly one line:
/// ```swift
/// APIConfiguration.environment = .staging
/// ```
enum APIConfiguration {
    /// Active API environment. Defaults to `.development` during Sprint 1.
    static var environment: APIEnvironment = .development

    static var baseURL: URL {
        guard let url = URL(string: environment.baseURLString) else {
            preconditionFailure("APIConfiguration.environment.baseURLString is not a valid URL")
        }
        return url
    }
}
