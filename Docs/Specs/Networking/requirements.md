# Requirements — Networking

Version: 1.3
Last updated: 2026-09-23
Status: implemented — Phases 1–4 landed; `NetworkServiceTests` (16 cases) pass.
`NetworkError.apiError` gained the envelope's `details` (v1.3); 401 token refresh
remains the one open ⚠️
Scope folder: `InnerLamp/Core/Networking/`

> See `changelog.md` in this folder for the version history of this spec.

> Mixed-mode spec, now effectively **retroactive** throughout: the parts that existed before this
> spec (`Endpoint`, `HTTPMethod`, `NetworkError`, `NetworkService`, `APIConfig`) state shipped
> behavior, and so do the four things it added (auth header, response envelope, session config,
> request logging) — those landed in Phases 1–4. The only open item is the token-refresh ⚠️ under
> Pending.

> This is an infrastructure spec, not a feature-scene spec. There is no screen, no Coordinator,
> and no ViewModel here — so `ui-builder` does not apply. The implementation work is
> `Core/`-layer Swift, and the consuming side (feature repositories) is
> `data-builder`'s job, not this spec's.

## User Story

As an InnerLamp feature developer, I want the `Core/Networking` layer to handle auth headers,
response-envelope decoding, timeouts, and request logging for me, so that every feature that calls
a business API does not have to re-implement those concerns — and cannot silently mis-decode an
error response because the failure shape was never modeled.

## Acceptance Criteria (EARS notation)

### Auth header

- WHEN a request is sent through `NetworkService` and a valid access token exists in the Keychain,
  THE SYSTEM SHALL attach `Authorization: Bearer <token>` to that request, without the caller's
  `Endpoint` having to declare it.
- WHEN no access token exists in the Keychain, THE SYSTEM SHALL send the request without an
  `Authorization` header — it SHALL NOT throw, block, or fabricate an empty token.
- WHEN an `Endpoint` explicitly declares its own `Authorization` value in `headers`, THE SYSTEM
  SHALL let that explicit value win, so a one-off endpoint can opt out of the stored token.
- WHEN an `Endpoint` declares `requiresAuth == false`, THE SYSTEM SHALL NOT attach any
  `Authorization` header, even if a valid token exists in the Keychain — a public endpoint (e.g.
  forgot-password, guest checkout, public catalog) must be able to guarantee no token is ever sent,
  rather than relying on the accidental absence of a declared header. `requiresAuth` defaults to
  `true` via a protocol-extension default, so every existing endpoint keeps its current (implicit)
  behavior untouched.

### Response envelope

- WHEN the server returns an HTTP 2xx with a body matching the `ApiResponse` envelope, THE SYSTEM
  SHALL decode the envelope and hand the caller only the `data` field, so no feature-level DTO
  ever models the envelope itself.
- WHEN the envelope carries `success = false` on an HTTP 2xx response, THE SYSTEM SHALL treat the
  call as failed and throw an error carrying the envelope's `error.code`, `error.message`, and
  `error.type`, plus the envelope's `details` map when it is present (surfaced as
  `[String: AnyCodable]?`), so a failure code that carries extra data (e.g. `locked_until`,
  `retry_after_seconds`) does not lose it in transit.
- WHEN the server returns an HTTP 4xx or 5xx whose body matches the `ApiResponse` envelope, THE
  SYSTEM SHALL throw an error carrying that envelope's `error.code`, `error.message`, and
  `error.type`, plus `details` when present, exactly as on the 2xx `success = false` path.
- WHEN an error response body does not parse as the envelope, THE SYSTEM SHALL throw
  `.serverError(statusCode:message:)` with `message` nil rather than crashing or attempting a
  second decode strategy.
- WHEN an endpoint is a metadata endpoint (localization) that does not speak the envelope, THE
  SYSTEM SHALL decode that response bare, with no envelope unwrapping.

### Error classification

- WHEN a request fails because the device has no connectivity, THE SYSTEM SHALL throw
  `NetworkError.noInternetConnection`.
- WHEN a request exceeds its timeout, THE SYSTEM SHALL throw `NetworkError.timeout`.
- WHEN the server returns HTTP 401, THE SYSTEM SHALL throw `NetworkError.unauthorized`, and SHALL
  NOT attempt a token refresh itself (see Out of scope).

### Session configuration

- WHEN the app performs any request, THE SYSTEM SHALL use a `URLSession` built from an explicit,
  inspectable `URLSessionConfiguration` rather than `URLSession.shared`, so timeout and
  connectivity behavior are defined in one place instead of inherited from the platform default.

### Request logging

- WHEN a request completes, THE SYSTEM SHALL emit one log record through `LoggingService`
  containing the HTTP method, path, status code, and duration.
- WHEN a request or response contains a credential (a bearer token, a password field), THE SYSTEM
  SHALL route it through `PIIMasker` before it reaches any log destination.
- WHEN a request fails, THE SYSTEM SHALL log the failure classification (`NetworkError` case or
  `ApiResponse.error.code`) — not the raw response body.

## Out of scope (permanently not this layer's responsibility)

- **Retry policy.** Explicitly deferred by the user: "tạm thời phần retry này làm động, khi nào
  cần tôi sẽ chỉ định sau." When a policy is specified, it gets its own spec revision — not a
  spontaneous addition here.
- **Token refresh on 401.** Whether a refresh call exists, who owns it, and whether it is
  transparent to callers is not decided. See the ⚠️ marker under Pending.
- **Multipart and `application/x-www-form-urlencoded` encoding.** The layer encodes JSON only.
  No feature currently needs file upload or form encoding.
- **Reachability pre-check before a request.** `NWPathMonitor` exists in
  `Core/Logging/MetricsCollector.swift` for metrics, but the networking layer does not gate
  requests on connectivity — it lets `URLError` classify the failure.

## Pending (not yet implemented — see `tasks.md`)

- Token refresh on 401 (see "Out of scope"). Still open — `.unauthorized` is thrown and reaches the
  feature as a plain failure.

  > ⚠️ Not confirmed: whether anything in the app is responsible for refreshing an expired token,
  > and if so whether that lives in `Core/Networking` or in the feature that receives the 401 —
  > blocks defining what happens after `.unauthorized` is thrown. Phases 1–4 are unaffected: the
  > flag's other job — gating the header on `requiresAuth` plus token presence — is implemented.

- Phase 3 test gap, carried from v1.2: no test drives a real timeout to `.timeout` and no test
  proves the configured session (not `.shared`) is the one used — `MockURLProtocol` never times
  out. This is the single unchecked item in `tasks.md` Phase 3; the values themselves (30s / 60s,
  `waitsForConnectivity = false`) are implemented and asserted indirectly.

## Open questions (resolved during implementation)

- ~~Does the envelope's `details` (`map[string]any`) need to be surfaced to callers at all, or are
  only `code`/`message`/`type` consumed?~~ → **Surfaced.** `details` decodes as
  `[String: AnyCodable]?` via a type-erased `AnyCodable` `Decodable` wrapper used only for
  `APIEnvelope.details`, and rides along on `NetworkError.apiError` (v1.3). Resolved 2026-09-15 by
  the user, then made load-bearing on 2026-09-22 when SignUp's 429 lock/cooldown cases needed
  `locked_until` / `retry_after_seconds` (see `Docs/Specs/SignUp/changelog.md` v1.11).
- ~~Is `ApiResponse`'s `data` ever absent on a successful call, or always present — does it decode
  as `T` or `T?`?~~ → Modeled `T?`, matching the backend's `omitempty`; a successful envelope with
  `data` absent throws `.noData`. Resolved 2026-09-15 by the user.
- ~~What are the concrete request/resource timeout values?~~ → 30s request / 60s resource,
  `waitsForConnectivity = false` (`NetworkConfiguration`). Resolved 2026-09-15 by the user.
- ~~What Keychain key string holds the access token?~~ → `"access_token"`
  (`KeychainAuthTokenProviding.accessTokenKey`). Resolved 2026-09-15 by the user.
- ~~How does the server discriminate between failure cases, given that `NetworkError.serverError`
  carries only a message string?~~ → The server wraps every business response in a standard
  envelope with a typed error object; the discriminator is `error.code`, not the message string.
  Resolved 2026-09-15 — see "Response envelope" above and `design.md` § "Envelope contract".

- ~~Which endpoints speak the envelope?~~ → All business APIs that call the backend. Metadata
  endpoints (localization) may differ and keep bare decoding. Resolved 2026-09-15.

- ~~Where does the auth token come from?~~ → The Keychain, under a fixed key. Resolved
  2026-09-15 for the storage location; the refresh question remains open (see Pending).
