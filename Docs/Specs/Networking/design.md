# Design — Networking

Version: 1.3
Last updated: 2026-09-23
Status: implemented — Phases 1–4 landed; `NetworkServiceTests` (16 cases) pass.
`NetworkError.apiError` now carries the envelope's `details`; 401 token refresh
remains the one open ⚠️
Scope folder: `InnerLamp/Core/Networking/`

> See `changelog.md` in this folder for the version history of this spec.

> **Retroactive throughout as of v1.3.** Every row below — including the ones still marked **new**
> or **modified**, which were the prospective work order in v1.0–v1.2 — now describes shipped code:
> `Endpoint`, `HTTPMethod`, `NetworkError`, `NetworkService`, `APIConfig`, plus the auth header,
> response envelope, session configuration, and request logging those phases added. The one
> exception is noted inline (the 401-refresh ⚠️).

> This is an infrastructure spec, not a feature-scene spec. There is no Coordinator, no ViewModel,
> no navigation flow, and no `DIContainer` factory to add. `il-screen-builder` does not apply. The
> consuming side — a feature's `Repository` calling `NetworkService` — is
> `il-data-layer-builder`'s job and is out of scope here.

## Overview

`Core/Networking` is the single transport boundary every business API call passes through: a
feature's `Repository` builds an `Endpoint`, hands it to `NetworkService`, and receives either a
decoded value or a `NetworkError`. `NetworkServiceImpl` is an `actor`, so concurrent calls from
several features serialize their decode work without a caller-side lock.

This spec upgrades that boundary in four ways, in the priority order chosen for it:

1. **Envelope decoding** — model the server's standard `ApiResponse` wrapper, so a failure is
   discriminated by `error.code` instead of by a human-readable message string.
2. **Auth header injection** — attach the stored bearer token centrally, so no feature endpoint
   declares it and no feature can forget it.
3. **Session configuration** — replace `URLSession.shared` with an explicitly configured, inspectable
   session so timeout and connectivity behavior are defined in one place.
4. **Request logging** — emit one structured record per request through the existing
   `LoggingService`, with credentials masked.

**Retry is deliberately not designed here.** The user deferred it ("tạm thời phần retry này làm
động, khi nào cần tôi sẽ chỉ định sau") — see "Deliberately deferred" below. Nothing in this spec
should be read as leaving room for an improvised retry loop.

## Layers & components

| Layer | File | Status | Responsibility |
|---|---|---|---|
| Transport / protocol | `Core/Networking/Endpoint.swift` | **modified** | Add a `responseEnvelope` property (`.standard` / `.bare`) with a protocol-extension default of `.standard`, so every existing endpoint keeps its current meaning and only a non-envelope endpoint opts out. Add a `requiresAuth: Bool` property with a protocol-extension default of `true`, so an endpoint that must never carry a token (public/anonymous action) declares that intent explicitly instead of relying on the accidental absence of a declared `Authorization` header. `buildURLRequest()` is otherwise unchanged. |
| Transport / verbs | `Core/Networking/HTTPMethod.swift` | existing | `HTTPMethod` enum. Unchanged. |
| Errors | `Core/Networking/NetworkError.swift` | existing (relocated in v1.1) | `NetworkError` moved here out of `HTTPMethod.swift` — a pure move, no case renamed — and gained `.apiError(code:message:type:details:)`: the envelope's discriminator plus its `details` map, so a failure code carrying extra data (`locked_until`, `retry_after_seconds`) keeps it. |
| Envelope model | `Core/Networking/APIEnvelope.swift` | existing | `APIEnvelope<T>`, `APIErrorDetail`, and the type-erased `AnyCodable` wrapper for `details`, mapping the backend's `ApiResponse` / `ErrorDetail` structs field for field. Never referenced outside `NetworkService`. |
| Auth | `Core/Networking/AuthTokenProvider.swift` | **new** | `AuthTokenProviding` protocol + `KeychainAuthTokenProviding`, the single place that knows which Keychain key holds the access token. |
| Session | `Core/Networking/NetworkConfiguration.swift` | **new** | Builds the one `URLSessionConfiguration` the app uses (timeouts, `waitsForConnectivity`), and the `URLSession` from it. |
| Observability | `Core/Networking/NetworkLogger.swift` | **new** | Turns one completed request into one `LoggingService` record — method, path, status, duration — routing anything credential-shaped through `PIIMasker` first. |
| Transport / service | `Core/Networking/NetworkService.swift` | **modified** | `NetworkServiceImpl` gains the auth header injection, envelope unwrapping, session injection, and logging call. **Both public method signatures stay exactly as they are** — see "No caller-visible signature change" below. |
| Host config | `Core/Networking/APIConfig.swift` | existing | `APIConfig.serverBaseURL` + `Environment`. Unchanged by this spec. |
| Metadata endpoints | `Core/Localization/LocalizationEndpoint.swift` | **possibly modified** | Only if localization is served through `NetworkService`: those endpoints declare `responseEnvelope = .bare`. **Verify by reading `LocalizationService.swift` before editing** — it may decode independently of `NetworkService`, in which case nothing here changes. |

**Naming:** none of these types carry an `IL` prefix. The `IL` convention belongs to the feature
layers (Domain / Presentation / Data); `Core` is unprefixed today (`NetworkService`, `Endpoint`,
`APIConfig`, `LocalizationService`) and this spec does not change that.

## No caller-visible signature change

```
Before:  func request<T: Decodable>(endpoint: Endpoint, responseType: T.Type) async throws -> T
After:   func request<T: Decodable>(endpoint: Endpoint, responseType: T.Type) async throws -> T
```

Identical. The envelope is unwrapped **inside** the service, so a feature `Repository` written
against today's `NetworkService` keeps compiling and keeps receiving `T`, never `APIEnvelope<T>`.
This is what makes the change safe to land before any feature has a real API integration.

The second overload — `func request(endpoint: Endpoint) async throws`, for responses with no body
the app needs — likewise keeps its signature and gains only the auth header and the log line.

## Request lifecycle (this spec's equivalent of a navigation flow)

```
Feature Repository
  │  IL<Feature>Mapper.toDTO(entity) → Endpoint(body: dto)
  ▼
NetworkServiceImpl.request(endpoint:responseType:)
  │
  ├─ 1. buildURLRequest()            (Endpoint, existing)
  │      baseURL + path + query, Content-Type/Accept,
  │      X-Session-ID / X-Correlation-ID from CorrelationContext
  │
  ├─ 2. inject Authorization         (new — AuthTokenProviding)
  │      token exists && endpoint didn't declare its own → Bearer <token>
  │      no token → header omitted, request still sent
  │
  ├─ 3. session.data(for:)           (new — NetworkConfiguration's URLSession)
  │
  ├─ 4. validateResponse(_:data:)    (existing — status → NetworkError)
  │
  ├─ 5. decode                       (new — APIEnvelope, unless .bare)
  │
  └─ 6. log                          (new — NetworkLogger)
         method, path, status, duration; failure logged as classification
```

## Envelope contract

The backend wraps business responses in a standard envelope. The Go source, verbatim from the
user, and its Swift mapping:

| Go | Swift | Notes |
|---|---|---|
| `type ErrorDetail struct { Code, Message, Type string }` | `struct APIErrorDetail: Decodable { let code, message, type: String }` | All three are `String` and all three are required — the envelope's `error` object either carries all three or is absent. |
| `ApiResponse.Success bool` | `let success: Bool` | HTTP 200 with `success: false` is a **failure**, not a success — this is the case the current code cannot express. |
| `ApiResponse.Data any` (`omitempty`) | `let data: T?` | Optional, matching `omitempty`. Resolved: `data` can legitimately be absent on success — that throws `.noData`, giving the previously unreachable case its throw site. |
| `ApiResponse.Error *ErrorDetail` (`omitempty`) | `let error: APIErrorDetail?` | Present only with `success: false`. |
| `ApiResponse.Details map[string]any` (`omitempty`) | `let details: [String: AnyCodable]?` | Resolved: surfaced — callers do consume it (SignUp's 429 `locked_until` / `retry_after_seconds`), so `NetworkError.apiError` carries it through. |

```swift
struct APIErrorDetail: Decodable {
    let code: String
    let message: String
    let type: String
}

struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: APIErrorDetail?
    let details: [String: AnyCodable]?
}
```

`AnyCodable` is a type-erased `Decodable` wrapper (confirmed by the user, v1.2), used only for
`APIEnvelope.details` — never for anything a caller decodes as a concrete type. It is
`@unchecked Sendable` because every value it holds comes from a `Decoder` and is never mutated
afterwards, and `NetworkError` — which now carries these details across the `NetworkServiceImpl`
actor boundary — must stay `Sendable`.

All four keys are single words, so the shared decoder's `.convertFromSnakeCase` leaves them alone —
no `CodingKeys` needed. This is only true because the envelope's own keys are flat; a nested
snake_case field inside `data` still converts as usual.

**Which endpoints speak the envelope.** All business APIs that call the backend. Metadata endpoints
(localization) may differ and keep bare decoding — hence the `responseEnvelope` flag rather than a
global switch.

**Failure discrimination.** `NetworkError.apiError(code:message:type:details:)` is the case that
carries the envelope's error. A feature's `Repository` maps it to its own `IL<Feature>Error` case
the same way it maps `.serverError` today. Rationale: `serverError(statusCode:message:)` alone
cannot distinguish two failures that share a status code, which is exactly what the envelope's
`code` exists for — and `details` is what lets a feature read a failure's extra data (e.g. SignUp's
`locked_until` / `retry_after_seconds` on the 429 cases) without the transport knowing what any
particular code means.

## Step-by-step Flow — One business request, end to end

Spelled out because the failure branches are where the current transport is wrong, and because
"decode the response" is otherwise a single sentence hiding four distinct outcomes.

```
Step 1 — Build the request
- Trigger: a feature Repository calls networkService.request(endpoint:responseType:)
- Pre-condition: the Endpoint is fully populated (path, method, optional body)
- Effect: Endpoint.buildURLRequest() → URLRequest with baseURL + path, Content-Type
  and Accept: application/json, plus X-Session-ID / X-Correlation-ID from
  CorrelationContext — all of this already exists, unchanged
    - Failure (URL cannot be formed) → throw .invalidURL, stop here

Step 2 — Inject the auth header
- Trigger: Step 1 produced a URLRequest
- Pre-condition: AuthTokenProviding reads the Keychain
- Effect: check `endpoint.requiresAuth` first, then fall back to token presence:
    - `requiresAuth == false` → never inject, no Keychain read is even meaningful here.
      This is for an endpoint that must guarantee no token is sent regardless of
      login state (e.g. forgot-password, guest checkout) — a deliberate declaration,
      not an inferred side effect of an endpoint simply not mentioning auth
    - `requiresAuth == true` (the default) AND a token exists AND the Endpoint's own
      `headers` did not already declare Authorization → set "Authorization: Bearer <token>"
    - `requiresAuth == true`, no token stored → send the request with no Authorization
      header. Do not throw, do not block, do not substitute an empty token: the
      endpoint may be public, and a failed login call cannot require a token to attempt
    - Endpoint declared its own Authorization → that explicit value wins over the
      stored token (but does not override `requiresAuth == false`, which always wins)

Step 3 — Execute
- Trigger: request ready
- Effect: the NetworkConfiguration URLSession performs the call
    - Transport failure, URLError .notConnectedToInternet or .networkConnectionLost
      → throw .noInternetConnection
    - Transport failure, URLError .timedOut → throw .timeout
    - Any other URLError → throw .unknown(error)
    - HTTP 401 → throw .unauthorized. No refresh is attempted — see "Deliberately
      deferred"
    - HTTP 2xx → Step 4
    - HTTP 4xx / 5xx → Step 5

Step 4 — Decode a 2xx response
- Trigger: HTTP 2xx received
- Pre-condition: endpoint.responseEnvelope
- Branch A — .standard (every business endpoint):
    - Decode APIEnvelope<T> from the body
        - Decode of the envelope itself fails → throw
          .serverError(statusCode:message: nil). No second decode strategy is
          attempted and nothing crashes — an unparseable body is one outcome, not two
        - success == true, data present → decode yielded T, go to Step 6
        - success == true, data absent → throw .noData (this gives the currently
          unreachable .noData case its real throw site)
        - success == false → throw .apiError(code: error.code,
          message: error.message, type: error.type, details: envelope.details)
- Branch B — .bare (metadata endpoints such as localization):
    - Decode T directly, no envelope unwrapping
    - Decode fails → throw .decodingError(error)

Step 5 — Decode a 4xx / 5xx response
- Trigger: HTTP 4xx or 5xx received
- Effect: attempt to decode the body as APIEnvelope<T>
    - Parses and carries an error → throw .apiError(code:message:type:details:)
    - Does not parse as the envelope → throw
      .serverError(statusCode:message: nil), as in Step 4
    - Note: 401 is already handled in Step 3, before this step, so it never reaches
      the envelope path

Step 6 — Log
- Trigger: the request has concluded, successfully or not
- Effect: NetworkLogger emits exactly one record through LoggingService containing
  HTTP method, path, status code, and duration
    - Anything credential-shaped (bearer token, password field) goes through
      PIIMasker before reaching the log destination
    - On failure, the record carries the classification — the NetworkError case, or
      the envelope's error.code — never the raw response body
- Note: logging must not change what the caller receives. A logging failure is
  swallowed; it never turns a successful request into a thrown error

Step 7 — Return
- Trigger: Steps 4–6 done
- Effect: return the decoded T to the Repository, or throw the NetworkError from
  Steps 1–5. The Repository maps NetworkError → IL<Feature>Error
  (il-data-layer-builder's job, out of scope here)
```

## Deliberately deferred (in this spec, not implemented)

These are named so that a future reader does not mistake their absence for an oversight — and so
that nobody adds them silently as a side effect of the four phases above.

- **Retry policy.** Deferred explicitly by the user: "tạm thời phần retry này làm động, khi nào cần
  tôi sẽ chỉ định sau." No retry count, no backoff, no retryable-error allowlist is designed here.
  When it is specified it gets its own spec revision — adding a retry loop to `NetworkServiceImpl`
  is not a mechanical follow-on to this work and must not be smuggled into it.
- **Token refresh on 401.** `.unauthorized` is thrown and that is the whole contract. Whether a
  refresh call exists, whether `Core/Networking` or the receiving feature owns it, and whether it is
  transparent to callers are all undecided — see the ⚠️ marker under Pending in `requirements.md`.
  Until that is answered, a 401 reaches the feature as a failure, which is the honest behaviour.
- **Multipart and `application/x-www-form-urlencoded` encoding.** JSON only. `Endpoint`'s
  `Content-Type` stays hardcoded to `application/json`; no feature needs file upload or form
  encoding today.
- **Reachability pre-check.** `NWPathMonitor` exists in `Core/Logging/MetricsCollector.swift` for
  metrics only. The networking layer does not gate requests on connectivity — `URLError` is allowed
  to classify the failure, which keeps a single source of truth for "no internet" instead of two
  that can disagree.

## Architecture note — transport-agnosticism (e.g. a future gRPC migration)

Not a work item in this spec; recorded so a future transport change is evaluated against the
boundary this spec already relies on, instead of rediscovering it from scratch.

`Domain` and `Presentation` never import `Endpoint`, `NetworkService`, or `NetworkError` directly —
only a feature's `Repository` (Data layer) does, and a `Repository` maps `NetworkError` to its own
`IL<Feature>Error` before returning to the `UseCase` (see "Failure discrimination" above). As long
as that mapping discipline holds, replacing REST/JSON with gRPC is a **Data-layer implementation
swap**, not a `Domain`/`Presentation` rewrite — the `Repository` protocol interface stays the same,
only what implements it changes.

What does **not** carry over as-is, and would need an equivalent, gRPC-shaped replacement rather
than a reused type:
- `Endpoint` (path, method, query) models REST; gRPC calls are service + method + a generated proto
  message. A new abstraction (e.g. a `GRPCCallable`-style protocol) would replace it, not extend it.
- `APIEnvelope` (`success` / `data` / `error`) is this backend's JSON convention; gRPC has its own
  failure shape (`Status` code, `google.rpc.Status` details). The **pattern** — one place that
  turns a transport-specific failure into a discriminated error before the `Repository` sees it —
  is what's reusable, not the `APIEnvelope` type itself.
- Auth injection becomes a gRPC `ClientInterceptor` attaching metadata instead of an `URLRequest`
  header; the *policy* this spec sets (`requiresAuth` opt-out, explicit-header override wins) is the
  part worth preserving, the mechanism is not.
- `NetworkConfiguration`'s `URLSessionConfiguration` has no gRPC equivalent — a gRPC channel has its
  own keepalive/deadline configuration surface.
- `NetworkLogger`'s fields (HTTP method, path, status code) would become gRPC's own (service,
  method, status code) — same responsibility, different field set.

Net effect: the isolation this spec establishes is what makes such a migration land as a scoped
`Core/Networking` rewrite instead of an app-wide one — but it is a rewrite of this folder's
contents, not a reuse of them. This note does not authorize starting that work; it is context for
whoever specs it if and when it is decided.

## Verification approach

`Core/Networking` has no unit test file today. Each phase in `tasks.md` adds coverage for the
behaviour it introduces — the envelope matrix in Phase 1 (success, `success: false`, unparseable
body, absent `data`, `.bare` bypass) is the one that matters most, since it is the change that can
silently corrupt every feature's error handling if it is wrong. Test doubles substitute
`AuthTokenProviding` and the `URLSession` (via `URLProtocol` or an injected configuration), never a
live network call.
