# Tasks — Networking

Version: 1.3
Last updated: 2026-09-23
Status: implemented — Phases 1–4 landed; `NetworkServiceTests` (16 cases) pass.
`NetworkError.apiError` now carries the envelope's `details` (v1.3); 401 token
refresh remains the one open ⚠️
Scope folder: `InnerLamp/Core/Networking/`

> See `changelog.md` in this folder for the version history of this spec.

> Every item below traces back to a row in `design.md`'s "Layers & components" table or a step in
> its "Step-by-step Flow". Nothing here is invented. The spec is now retroactive: the boxes are
> ticked because the work shipped, not because the spec was written.

> **Phase order is deliberate.** Phase 1 comes first because it is the one that unblocks feature
> work: a feature's `Repository` cannot map a failure case to its own `IL<Feature>Error` until the
> transport can tell it *which* failure occurred. Phases 2–4 are real but no feature is blocked on
> them.

## Phase 1 — Response envelope (unblocks feature API integration)

- [x] Create `Core/Networking/APIEnvelope.swift` — `APIEnvelope<T>` and `APIErrorDetail`, field
      for field against the Go source in `design.md` § "Envelope contract"
- [x] Resolve the two ⚠️ markers this phase depends on (`details` surfacing, `data` optionality) —
      see `requirements.md` Pending; do not pick an answer in code, ask
- [x] Relocate `NetworkError` from `Core/Networking/HTTPMethod.swift` into a new
      `Core/Networking/NetworkError.swift` — pure move, no case renamed, no behaviour change
- [x] Add `NetworkError.apiError(code:message:type:)` — the envelope's discriminator — then
      extend it to `apiError(code:message:type:details:)` once the envelope's `details` is needed
      (v1.3): the discriminator alone cannot carry a failure's extra data (`locked_until`,
      `retry_after_seconds`)
- [x] Forward `envelope.details` on both failure paths of `NetworkServiceImpl` — the 2xx
      `success == false` branch and the 4xx/5xx branch — not just one of them, so the same failure
      code behaves identically whichever HTTP status carries it
- [x] Provide an `AnyCodable` initializer for hand-built values (tests/fixtures) and mark it
      `@unchecked Sendable`, since `NetworkError` must stay `Sendable` to cross the
      `NetworkServiceImpl` actor boundary
- [x] Tests: `test_apiError_carriesEnvelopeDetails` — a 429-shaped envelope's `details` reaches the
      caller intact
- [x] Add `responseEnvelope` to the `Endpoint` protocol, with a protocol-extension default of
      `.standard` so every existing endpoint keeps its current meaning without being touched
- [x] Modify `NetworkServiceImpl.request<T>(endpoint:responseType:)` to decode `APIEnvelope<T>`
      and unwrap `data` — **public signature unchanged** (`design.md` § "No caller-visible
      signature change")
- [x] Implement the 2xx branches: `success == false` → `.apiError`; `data` absent → `.noData`
      (giving the currently unreachable case its real throw site); envelope unparseable →
      `.serverError(statusCode:message: nil)` — no second decode attempt
- [x] Implement the 4xx/5xx branch: envelope-shaped body → `.apiError`; otherwise
      `.serverError(statusCode:message: nil)`. Confirm 401 still short-circuits before this branch
- [x] Implement the `.bare` path — decode `T` directly, no unwrapping
- [x] Verify whether localization is served through `NetworkService` by reading
      `Core/Localization/LocalizationService.swift`; if it is, give its endpoints
      `responseEnvelope = .bare`. If it decodes independently, change nothing there and say so
- [x] Tests: envelope matrix — `success: true` with `data`; `success: false` with `error`; 2xx with
      an unparseable body; `success: true` with `data` absent; `.bare` bypass; 401 still
      `.unauthorized`
- [x] `xcodebuild build` + `xcodebuild test` pass — report the real output

## Phase 2 — Auth header injection

- [x] Resolve the ⚠️ marker this phase depends on: the exact Keychain key the access token is
      stored under. `il-data-layer-builder` needs the same answer for the login repository — do not
      invent a key string
- [x] Create `Core/Networking/AuthTokenProvider.swift` — `AuthTokenProviding` protocol, plus a
      `Keychain`-backed implementation reading through the existing `KeychainService` from
      `Core/Storage/`. Inject the protocol, never a concrete instance, so tests can substitute it
- [x] Add `requiresAuth: Bool` to the `Endpoint` protocol, with a protocol-extension default of
      `true` — an endpoint that must never carry a token regardless of Keychain state (e.g.
      forgot-password, guest checkout) sets it to `false` explicitly, instead of relying on the
      accidental absence of a declared `Authorization` header
- [x] Modify `NetworkServiceImpl` to inject the Authorization header when
      `endpoint.requiresAuth == true`, a token exists, and the endpoint did not declare its own
      `Authorization` value
- [x] Handle the `requiresAuth == false` path: never inject, never read the Keychain for this
      purpose, no matter whether a token exists
- [x] Handle the no-token path: send the request with no `Authorization` header. Do not throw, do
      not block, do not fabricate an empty token
- [x] Handle the explicit-override path: an endpoint's own `Authorization` header wins over a
      stored token (but `requiresAuth == false` still wins over an explicit header, since it is a
      stronger guarantee: no token, period)
- [x] Provide the token provider in `DIContainer` from the existing `keychainService` lazy var
      (`Core/Networking` has no `DIContainer` factory of its own — this is a constructor argument
      to the `NetworkService` factory, not a new feature section)
- [x] Tests: token present → header set; no token → header absent and request still sent; endpoint
      declares its own → declared value wins; `requiresAuth == false` → never set even with a
      valid token present; a token never appears in any log output
- [x] `xcodebuild build` + `xcodebuild test` pass — report the real output

  > ⚠️ Not confirmed: whether anything in the app refreshes an expired token, and if so whether
  > that lives in `Core/Networking` or in the feature that receives the 401 — blocks defining what
  > happens *after* `.unauthorized` is thrown. Until answered, `.unauthorized` reaches the feature
  > as a plain failure. Do not add a refresh call in this phase.

## Phase 3 — Session configuration

- [x] Resolve the ⚠️ marker this phase depends on: the concrete request/resource timeout values.
      If no value is specified, stop and ask rather than shipping a guessed number presented as
      deliberate
- [x] Create `Core/Networking/NetworkConfiguration.swift` — one explicit `URLSessionConfiguration`
      (timeouts, `waitsForConnectivity`) and the `URLSession` built from it
- [x] Replace `URLSession.shared` as `NetworkServiceImpl`'s session — keep the `session:` init
      parameter so tests can inject a substitute
- [x] Confirm the decoder configuration (`.convertFromSnakeCase`, `.iso8601`) and the unconfigured
      `JSONEncoder` are untouched — the encoding asymmetry is a known property of this layer, not a
      bug to fix here
- [ ] Tests: a request that exceeds the configured timeout → `.timeout`; the session used is the
      configured one, not `.shared`
- [x] `xcodebuild build` + `xcodebuild test` pass — report the real output

## Phase 4 — Request logging

- [x] Create `Core/Networking/NetworkLogger.swift` — one record per completed request through the
      existing `LoggingService`, carrying HTTP method, path, status code, and duration
- [x] Route credential-shaped values (bearer token, password fields) through `PIIMasker` before
      they reach any log destination
- [x] Log failures as a classification — the `NetworkError` case, or the envelope's `error.code` —
      never the raw response body
- [x] Guarantee logging cannot change the outcome: a logging failure is swallowed and never turns a
      successful request into a thrown error
- [x] Tests: one record per request; a bearer token never appears in the emitted record; a failure
      logs the classification and not the body
- [x] `xcodebuild build` + `xcodebuild test` pass — report the real output

## Phase 5 — Verification

- [x] `git status` shows no edits outside `InnerLamp/Core/Networking/` (plus the `DIContainer`
      constructor argument from Phase 2, and `Core/Localization/LocalizationEndpoint.swift` **only**
      if Phase 1 proved localization routes through `NetworkService`)
- [x] Confirm no feature-layer file changed: `Domain/`, `Presentation/`, `Data/` untouched by this
      spec's work
- [ ] Confirm the two public `NetworkService` method signatures are byte-identical to before
      (`git diff` on `NetworkService.swift`) — the envelope must be invisible to callers
- [x] Confirm the 9 pre-existing `NetworkError` cases all still exist with unchanged payloads, and
      `.noData` now has a real throw site (it had none before this work)
- [x] Tick the boxes above that were genuinely completed in the same run — nothing else
- [x] Append the `changelog.md` entry and bump the shared version across all three headers
      (header lines and checkboxes only, never a line of prose)

## Deferred (specified elsewhere, not blocking this spec)

- **Retry policy** — deferred by the user ("tạm thời phần retry này làm động, khi nào cần tôi sẽ
  chỉ định sau"). Needs a policy decision before it can be specced: retry count, backoff shape,
  which `NetworkError` cases are retryable, and whether retry is transparent to callers.
- **Token refresh on 401** — blocked on the same ⚠️ as recorded under Pending in `requirements.md`.
  If it lands, it is its own spec revision, not a Phase 2 addendum.
- **Multipart / form-urlencoded encoding** — no feature needs file upload or form encoding today.
- **Reachability pre-check** — deliberately not added; `URLError` classification stays the single
  source of truth.
- **Moving `NetworkError` a second time** — Phase 1 relocates it once, out of `HTTPMethod.swift`.
  Any further reorganisation of `Core/Networking`'s files is not part of this spec.
