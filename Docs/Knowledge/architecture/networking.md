---
type: Architecture Pattern
title: Networking Layer
description: The single transport boundary every business API call passes through — a feature Repository builds an Endpoint, hands it to NetworkService, and receives a decoded value or a NetworkError.
resource: InnerLamp/Core/Networking/NetworkService.swift
tags: [architecture, networking]
status: stable
generated: { by: claude-code, at: 2026-09-27T14:54:58+07:00 }
sources:
  - path: Docs/Specs/Networking/design.md
    kind: spec
  - path: InnerLamp/Core/Networking/NetworkService.swift
    kind: code
  - path: InnerLamp/Core/Networking/Endpoint.swift
    kind: code
  - path: InnerLamp/Core/Networking/APIEnvelope.swift
    kind: code
---

# Summary

`Core/Networking` is the transport boundary every business API call passes
through. A feature's `Repository` (Data layer) builds an `Endpoint`, hands it to
`NetworkService`, and receives either a decoded value or a `NetworkError`.
`NetworkServiceImpl` is an `actor`, so concurrent calls from several features
serialize their decode work without a caller-side lock.

The boundary handles four cross-cutting concerns centrally — envelope decoding,
auth-header injection, session configuration, and request logging — so no feature
re-implements them and none can silently mis-decode an error. `Domain` and
`Presentation` never import `Endpoint` / `NetworkService` / `NetworkError`
directly; only the Repository does, and it maps `NetworkError` to its own
`IL<Feature>Error` before returning to the UseCase.

# The rule

A feature's `Repository` must be the **only** thing that imports `Core/Networking`.
It maps `NetworkError` to its own `IL<Feature>Error` (discriminating on the
envelope's `error.code`, never the human-readable message) before returning to
the UseCase. This keeps `Domain` and `Presentation` transport-agnostic, so a
future gRPC migration is a Data-layer implementation swap, not a
Domain/Presentation rewrite.

# Shape

```
Feature Repository
  │  IL<Feature>Mapper.toDTO(entity) → Endpoint(body: dto)
  ▼
NetworkServiceImpl.request(endpoint:responseType:)
  ├─ 1. buildURLRequest()      baseURL + path + query, Content-Type/Accept,
  │                            X-Session-ID / X-Correlation-ID (CorrelationContext)
  ├─ 2. inject Authorization   token exists && endpoint didn't declare its own → Bearer <token>
  ├─ 3. session.data(for:)     NetworkConfiguration's URLSession
  ├─ 4. status → NetworkError  2xx / 401 / 4xx-5xx
  ├─ 5. decode                 APIEnvelope<T> (unless .bare)
  └─ 6. log                    NetworkLogger (method, path, status, duration; PII-masked)
```

## Components

| File | Responsibility |
|---|---|
| `Core/Networking/Endpoint.swift` | `Endpoint` protocol (`baseURL`, `path`, `method`, `headers`, `queryParameters`, `body`, `responseEnvelope`, `requiresAuth`) + `buildURLRequest()` |
| `Core/Networking/HTTPMethod.swift` | `HTTPMethod` enum |
| `Core/Networking/NetworkError.swift` | `NetworkError`, incl. `apiError(code:message:type:details:)` — the envelope discriminator |
| `Core/Networking/APIEnvelope.swift` | `APIEnvelope<T>`, `APIErrorDetail`, `AnyCodable` — the backend's `ApiResponse` / `ErrorDetail` |
| `Core/Networking/AuthTokenProvider.swift` | `AuthTokenProviding` + `KeychainAuthTokenProviding` — the single owner of the access-token Keychain key |
| `Core/Networking/NetworkConfiguration.swift` | The one `URLSessionConfiguration` + `URLSession` (timeouts, `waitsForConnectivity`) |
| `Core/Networking/NetworkLogger.swift` | One `LoggingService` record per request, credential-shaped data through `PIIMasker` |
| `Core/Networking/NetworkService.swift` | `NetworkServiceImpl` (actor) — auth injection, envelope unwrapping, logging |
| `Core/Networking/APIConfig.swift` | `serverBaseURL` + `Environment` (currently mock hosts) |

# Envelope contract

The backend wraps business responses in `{"success", "data", "error", "details"}`.
`responseEnvelope` (`.standard` default / `.bare`) lets metadata endpoints opt
out. Failures are discriminated by `error.code`, and `details` carries extra data
(`locked_until`, `retry_after_seconds`) through `NetworkError.apiError`.

# Canonical example

`Data/Repositories/ILSignUpRepositoryImpl.swift` is the representative consumer:
it builds `RequestRegistrationOTPEndpoint`, calls `NetworkService`, maps the
response via `ILSignUpMapper`, and converts `NetworkError` → `ILSignUpError` via
an exhaustive `ILSignUpError.from(_:)` (see `features/signup.md`). `ILOtpRepositoryImpl`
is the second, verify/resend-aware example.

# Common mistakes

- Reading the `error.message` string to branch a failure — it is not a stable
  discriminator; use `error.code`.
- Declaring a feature `Endpoint` in `Core/Networking/` — endpoints live under
  `Data/DataSources/Remote/`, since `Core/Networking/` is fixed infrastructure.
- Forgetting `requiresAuth = false` on a public endpoint — a stray
  `Authorization` header is then attached when a token exists.

# Deliberately deferred

- **Retry policy** — deferred by the user; no retry/backoff is implemented.
- **Token refresh on 401** — `.unauthorized` is thrown and that is the whole
  contract; refresh ownership is undecided.
- **Multipart / form-urlencoded** — JSON only; `Content-Type` is hardcoded.
- **Reachability pre-check** — `NWPathMonitor` is metrics-only; `URLError`
  classifies connectivity failures.

# Related concepts

- [Logging groups](logging-groups.md) — `NetworkLogger` routes to `LoggingService`
  (Group 1) and `CorrelationContext` ties request headers to Flow Tracking.
- [Sign Up](../features/signup.md), [OTP Verification](../features/otp.md) — the
  consumers whose error mapping is the canonical example.
