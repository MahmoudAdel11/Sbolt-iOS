# Yalla Go — Backend Integration Foundation

Sprint 1 | 2026-08-05

---

## Architecture

The networking layer follows a **decorator / dependency-injection** pattern. No singletons are introduced. Every dependency flows inward from `AppEnvironment` → `RepositoryFactory` → repositories → use cases → view models.

```
AppEnvironment.current
    └── RepositoryFactory
            ├── MockRepositoryFactory        (development — in-memory)
            └── RemoteRepositoryFactory      (production — live API)
                    └── AuthenticatedAPIClient   [decorator]
                            └── URLSessionAPIClient  [concrete transport]
                                    └── Endpoint  [value type — one request]
```

---

## Networking Flow

```
ViewModel
  │
  ▼
UseCase.execute()
  │
  ▼
Repository.method()          (protocol — domain boundary)
  │
  ▼
RemoteXxxRepository
  │
  ▼
AuthenticatedAPIClient.send(endpoint)
  │  ← injects Authorization: Bearer <token>  (if token exists)
  ▼
URLSessionAPIClient.send(endpoint)
  │  ← builds URLRequest
  │  ← executes via URLSession
  │  ← logs request + response  (DEBUG only)
  │  ← maps status codes → NetworkError
  │  ← decodes JSON → T: Decodable
  ▼
Result<T, NetworkError>  thrown back up the chain
```

---

## Files

| File | Role |
|---|---|
| `Core/Networking/HTTPMethod.swift` | HTTP verb enum (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`) |
| `Core/Networking/Endpoint.swift` | Value type — path, method, headers, query items, body |
| `Core/Networking/NetworkError.swift` | Typed error enum covering all HTTP + URLSession failure cases |
| `Core/Networking/APIConfiguration.swift` | `APIEnvironment` enum + `APIConfiguration.baseURL` — single line to change env |
| `Core/Networking/APIClient.swift` | `APIClient` protocol + `URLSessionAPIClient` (transport, logging, error mapping) |
| `Core/Networking/TokenProvider.swift` | `TokenProvider` protocol + `NilTokenProvider` (no-op default) |
| `Core/Networking/AuthenticatedAPIClient.swift` | Decorator — injects Bearer token from `TokenProvider` |
| `Core/Networking/NetworkLogger.swift` | DEBUG-only console logger (compiled out in Release) |
| `Core/DI/AppEnvironment.swift` | `.development` / `.production` switch — controls mock vs remote |
| `Core/DI/RepositoryFactory.swift` | `MockRepositoryFactory` + `RemoteRepositoryFactory` |

---

## Dependency Graph

```
TokenProvider (protocol)
    └── NilTokenProvider          ← Sprint 1 default (no auth header)
    └── KeychainTokenProvider     ← Sprint 2 (implement after login)

APIClient (protocol)
    └── URLSessionAPIClient       ← concrete transport
    └── AuthenticatedAPIClient    ← decorator, wraps any APIClient

RepositoryFactory (protocol)
    └── MockRepositoryFactory     ← all mock impls
    └── RemoteRepositoryFactory   ← AuthenticatedAPIClient + all remote impls
            accepts: TokenProvider

AppEnvironment.current            ← single switch: .development | .production
    └── .repositoryFactory        ← returns Mock or Remote factory
```

---

## Environment Switching

Two independent switches exist with different scopes:

| Switch | What it controls | Where |
|---|---|---|
| `AppEnvironment.current` | Mock data vs live network | `AppEnvironment.swift` |
| `APIConfiguration.environment` | Which server URL (dev / staging / prod) | `APIConfiguration.swift` |

Typical configurations:

```swift
// Local development — mock data, no network
AppEnvironment.current         = .development
APIConfiguration.environment   = .development   // irrelevant, not used

// Integration testing — live dev server
AppEnvironment.current         = .production
APIConfiguration.environment   = .development

// Production release
AppEnvironment.current         = .production
APIConfiguration.environment   = .production
```

---

## NetworkError Cases

| Case | HTTP / URLError trigger |
|---|---|
| `invalidURL` | `Endpoint.url()` returned nil |
| `unauthorized` | 401 |
| `forbidden` | 403 |
| `notFound` | 404 |
| `conflict` | 409 |
| `serverError(statusCode:message:)` | Any other non-2xx |
| `noData` | 2xx with empty body |
| `decodingFailed(_)` | `JSONDecoder` threw |
| `timeout` | `URLError.timedOut` |
| `noInternet` | `URLError.notConnectedToInternet` / `.networkConnectionLost` / `.dataNotAllowed` |
| `requestCancelled` | `URLError.cancelled` |
| `unknown(_)` | Anything else |

---

## DEBUG Request Logging

`NetworkLogger` (compiled out in Release) prints to the console:

```
▶ REQUEST
POST  https://dev-api.yallago.com/v1/auth/login
Headers: ["Content-Type": "application/json", "Accept": "application/json"]
Body: {"email":"user@example.com","password":"..."}

◀ RESPONSE
200  https://dev-api.yallago.com/v1/auth/login  [143ms]
Body: {"id":"abc","username":"mahmoud", ...}
```

---

## Future Extension Points

### Sprint 2 — Authentication

1. Implement `KeychainTokenProvider: TokenProvider` that reads/writes to the system Keychain.
2. Wire `RemoteAuthenticationRepository.login()` — replace the `throw 501` stub with `client.send(.login(...))`.
3. On successful login, store the token via `KeychainTokenProvider`.
4. Pass the provider into `RemoteRepositoryFactory(tokenProvider: keychainProvider)`.
5. Drive `AppSessionStore.isAuthenticated` from `GetCurrentUserUseCase`.

### Sprint 3 — Token Refresh

1. Add `refreshToken()` to `TokenProvider`.
2. Wrap `AuthenticatedAPIClient` with a `TokenRefreshAPIClient` that catches `NetworkError.unauthorized`, refreshes, and retries once.

### Sprint 4 — Feature Repositories

Replace the `throw 501` stubs in:
- `RemoteProfileRepository`
- `RemoteTripRepository`
- `RemoteFavoritePlaceRepository`

Each requires only: define `Endpoint` extension cases, fill in `toDomain()` on the DTO, and call `client.send(...)`.

### Endpoint Catalogue

Add a file `Core/Networking/Endpoint+Routes.swift` grouping all endpoint definitions as static factory methods:

```swift
extension Endpoint {
    static func login(email: String, password: String) -> Endpoint { ... }
    static var profile: Endpoint { ... }
    static func trips(page: Int) -> Endpoint { ... }
}
```

This keeps endpoint definitions out of repositories and makes them independently testable.
