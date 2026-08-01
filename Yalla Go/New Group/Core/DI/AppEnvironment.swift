
//
//  AppEnvironment.swift
//  Yalla Go
//

// MARK: - Environment

/// Controls which repository implementations the entire app uses.
///
/// **To switch from Mock to Remote — change exactly one line:**
/// ```swift
/// // Development (current default — no network, in-memory data):
/// AppEnvironment.current = .development
///
/// // Production (live Yalla Go backend via URLSession):
/// AppEnvironment.current = .production
/// ```
///
/// Each `*Dependencies` struct accepts the repository produced by
/// `AppEnvironment.current.repositoryFactory` as a constructor argument,
/// so no ViewModels or views need to change when the environment is switched.
enum AppEnvironment {
    case development
    case production

    /// The active environment. Defaults to `.development` (mock data, no network).
    static var current: AppEnvironment = .development

    /// The repository factory for this environment.
    var repositoryFactory: any RepositoryFactory {
        switch self {
        case .development: return MockRepositoryFactory()
        case .production:  return RemoteRepositoryFactory()
        }
    }
}
