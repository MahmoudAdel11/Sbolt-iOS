
//
//  AppEnvironment.swift
//  Yalla Go
//

import Foundation

// MARK: - Environment

/// Controls which repository implementations the entire app uses.
///
/// **To switch from Remote back to Mock — change exactly one line:**
/// ```swift
/// // Development (no network, in-memory data):
/// AppEnvironment.current = .development
///
/// // Production (real backend via URLSession — see `APIConfiguration` for
/// // which host: defaults to http://localhost:8000, change that separately
/// // to point at staging/production):
/// AppEnvironment.current = .production
/// ```
///
/// Each `*Dependencies` struct accepts the repository produced by
/// `AppEnvironment.current.repositoryFactory` as a constructor argument,
/// so no ViewModels or views need to change when the environment is switched.
enum AppEnvironment {
    case development
    case production

    /// The active environment. Defaults to `.production` (real backend, via
    /// `RemoteRepositoryFactory` + `APIConfiguration.baseURL`) for the actual
    /// running app — SwiftUI Previews always fall back to `.development`
    /// (mock data) below instead, since a preview canvas has no reliable
    /// network access and previewing sample UI shouldn't depend on a running
    /// local backend. Every `*View_Previews` in the app already constructs
    /// its `*Dependencies` with no explicit repository, so this is the one
    /// place that needs to know about previews — no preview call site changes.
    static var current: AppEnvironment = isRunningInPreviews ? .development : .production

    private static var isRunningInPreviews: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    /// The repository factory for this environment.
    var repositoryFactory: any RepositoryFactory {
        switch self {
        case .development: return MockRepositoryFactory()
        case .production:  return RemoteRepositoryFactory()
        }
    }
}
