# Backend Backlog

Items identified during Sprints 2-7 (backend integration + production polish) that are not implemented — confirmed against the actual backend source, not assumed. None of these block current functionality; tracked here for future prioritization.

## Refresh token support

The backend issues a JWT with a fixed 30-minute TTL (`app/core/config.py` → `access_token_expire_minutes = 30`) and has no `/auth/refresh`-style endpoint — `TokenResponse` returns only `{access_token, token_type}`, no refresh token. Confirmed intentionally deferred: `app/api/v1/routes/auth.py` has an explicit `# TODO(phase-3): refresh tokens.` comment.

Client-side impact: sessions hard-expire after 30 minutes with no silent renewal. Sprint 7 improved the UX around this (clear "session expired" messaging, automatic sign-out) but did not — and should not — work around the missing endpoint client-side.

## Ride Tiers

No ride-tier/type concept exists anywhere in the backend (`RideRequestSchema`, `RideResponse` — lat/lng only, no tier field). The iOS app currently computes a single implicit-default-tier fare estimate client-side and doesn't expose tier selection in the booking UI. Needs backend schema work (a tier field + pricing rules) before this can become a real feature.

## Driver-details endpoint

Confirmed: no `/drivers` endpoint, no `Driver` schema, and no driver-specific data (name, rating, vehicle, plate) exists at any layer — a driver is just a `User` with `role="driver"`. `GET /rides/{id}` exposes only a bare `driver_id`. The iOS `Driver` domain model's rich fields are all optional and populated as `nil` from the remote repository as a result.

## "Ongoing" ride status is currently unreachable

The backend has `RideStatus.ONGOING` in its enum, but no transition endpoint reaches it — `POST /rides/{id}/accept` moves `requested` → `accepted` directly, and `POST /rides/{id}/complete` accepts either `accepted` or `ongoing` as the pre-completion state. There is no "start ride" endpoint that would move `accepted` → `ongoing`. Confirmed via an explicit code comment in the backend's `CompleteRideUseCase`. Ride History correctly renders the `ongoing` status if it ever appears, but no live-created ride can currently reach it.
