# Changelog — Networking Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this folder. All
three files share one changelog since they change together as one spec unit. Newest version first.

## v1.3 (2026-09-23)

- `requirements.md`: the two envelope failure criteria now require the error to carry `details`
  when present (not just `code`/`message`/`type`). The "Pending" section was rewritten — it still
  listed Phases 1–4 as unimplemented work with four ⚠️ markers, all of which had in fact been
  resolved and shipped in v1.2; it now holds only the genuinely open token-refresh ⚠️ and the
  known Phase 3 timeout-test gap. The four resolved ⚠️s (details surfacing, `data` optionality,
  timeout values, Keychain key) moved to "Open questions (resolved)". The mixed-mode note is now
  "retroactive throughout".
- `design.md`: the Layers table describes `NetworkError` as
  `apiError(code:message:type:details:)` and `APIEnvelope` as including the `AnyCodable` wrapper
  (both now shipped rather than "new"); the mixed-mode preamble is now retroactive; the envelope
  contract table's `data` and `details` rows state their resolutions instead of ⚠️ markers; the
  `APIEnvelope` code block drops its pending comment and gains a paragraph on `AnyCodable`'s
  `@unchecked Sendable` rationale; "Failure discrimination" and Steps 4–5 now show the `details`
  argument, with the reason a feature needs it (SignUp's 429 lock/cooldown timing).
- `tasks.md`: the "every box starts `[ ]`" preamble is corrected to retroactive; Phase 1's
  `apiError` item now records the v1.3 `details` extension, and three items were added for work
  that shipped with it (forward `details` on both failure paths; the `AnyCodable` hand-built
  initializer + `Sendable`; `test_apiError_carriesEnvelopeDetails`).
- `NetworkServiceTests` is now 16 cases (was 15).
- Reason: v1.2 recorded a deviation and left the prose alone; the SignUp integration (changelog
  `Docs/Specs/SignUp/changelog.md` v1.11) then made `details` load-bearing for the 429 cases, and
  that change was flagged there as "owed" to this spec. This version is that sync — no design
  change, a documentation correction.

## v1.2 (2026-09-15)

- `requirements.md`: header only — Status moved from "not started" to "implemented"; no line of
  prose changed.
- `design.md`: header only — same Status change; no line of prose changed. The four ⚠️ markers
  that blocked Phases 1–3 were resolved by the user before implementation (see below), so the
  design as written is what shipped, with one recorded deviation:
  - `NetworkServiceImpl`'s second overload declares `endpoint: any Endpoint` while its protocol
    requirement declares `endpoint: Endpoint`. Same type in current Swift, but not byte-identical
    to the protocol line. Recorded, not corrected — a signature edit is prose, not this entry's.
- `tasks.md`: Phases 1–4 ticked (34 boxes) — envelope model + decode matrix, auth header injection
  with `requiresAuth` opt-out, explicit `NetworkConfiguration` session, and per-request logging.
  Two boxes left `[ ]`, both for cause:
  - Phase 3 "Tests: a request that exceeds the configured timeout → `.timeout`; the session used
    is the configured one, not `.shared`" — only the configuration values (30/60/`false`) are
    asserted; no test drives a real timeout to `.timeout`, and no test proves `.shared` is not
    used. The `MockURLProtocol` never times out.
  - Phase 5 "Confirm the two public `NetworkService` method signatures are byte-identical to
    before (`git diff` on `NetworkService.swift`)" — cannot be confirmed by `git diff`: the whole
    `Core/Networking/` folder is untracked (no baseline commit), so there is no "before" to diff
    against. Verified instead against `design.md` § "No caller-visible signature change": the
    generic overload matches exactly; the second differs only by `any` on the parameter type.
- The four ⚠️ markers this version resolves, and the value each was resolved to (confirmed by the
  user, not invented by the implementer):
  - Keychain key for the access token → `"access_token"` (`KeychainAuthTokenProviding.accessTokenKey`).
  - Request / resource timeout → `30s` / `60s`, `waitsForConnectivity = false`.
  - `details` (`map[string]any`) → surfaced as `[String: AnyCodable]?` via a new `AnyCodable`
    type-erased `Decodable` wrapper, used only for `APIEnvelope.details`.
  - `data` optionality → modeled `T?` (matching the backend's `omitempty`); a successful envelope
    with `data` absent throws `.noData`, which gives that previously unreachable case its real
    throw site.
- 401 token refresh remains unimplemented, per the still-open ⚠️ on Phase 2 — `.unauthorized` is
  thrown and reaches the feature as a plain failure, as the spec requires.
- Reason: `Core/Networking/` Phases 1–4 were implemented and `NetworkServiceTests` (15 cases,
  covering the envelope matrix, auth-header matrix, and logging) pass under
  `xcodebuild test -project InnerLamp.xcodeproj -scheme InnerLamp`. This entry records the
  work that landed; it makes no design change.

## v1.1

- Reviewed against a question the user raised after v1.0: was the auth-header design flexible
  enough for endpoints that don't need auth, and what does a future gRPC migration cost given this
  spec's boundaries? Both are addressed without touching the four phases' scope or order.
- `requirements.md` / `design.md` / `tasks.md` (Phase 2): added `requiresAuth: Bool` to the
  `Endpoint` protocol, default `true` via a protocol-extension default (every existing endpoint
  keeps today's implicit behavior unchanged). Rationale: the v1.0 design only let an endpoint opt
  out of the stored token by declaring its *own* `Authorization` value — there was no way for a
  public endpoint (forgot-password, guest checkout) to guarantee no token is ever attached, even
  when one exists in the Keychain, without accidentally repurposing "I have my own Authorization
  value" as "I refuse a token." `requiresAuth == false` now expresses that refusal directly and
  always wins, even over an explicit header override.
- `design.md`: Step 2 of the Step-by-step Flow reordered to check `requiresAuth` first, before the
  token-presence branch.
- `design.md`: added a new "Architecture note — transport-agnosticism (e.g. a future gRPC
  migration)" section. Not a work item — it records that `Domain`/`Presentation` never see
  `Endpoint`/`NetworkService`/`NetworkError` directly (only a `Repository` does, and it maps to its
  own `IL<Feature>Error`), so a transport change from REST/JSON to gRPC would be a scoped
  `Core/Networking` + `Repository`-implementation rewrite, not an app-wide one — while being
  explicit that `Endpoint`, `APIEnvelope`, and `NetworkConfiguration` themselves have no gRPC
  equivalent and would be replaced, not reused. No gRPC work is scheduled; this is context for
  whoever specs it if and when it is decided.
- No change to Phases 1, 3, 4, or 5, and no change to the "Deliberately deferred" / "Out of scope"
  items (retry, 401 refresh, multipart, reachability pre-check).

## v1.0 (initial)

- Initial spec for `InnerLamp/Core/Networking/`, written **before** the work — a two-part spec
  unit, **retroactive** for the transport that already ships (`Endpoint`, `HTTPMethod`,
  `NetworkError`, `NetworkService`, `APIConfig`) and **prospective** for the four upgrades it
  scopes (`requirements.md` § "Acceptance Criteria", `tasks.md` Phases 1–4, all boxes `[ ]`).
- `requirements.md`: user story + EARS acceptance criteria across four areas — auth header,
  response envelope, error classification, session configuration, request logging. Records the
  scope the user chose verbatim ("Auth token + Authorization header, Error code discriminator,
  URLSession config + timeout, Retry + log request/response") and marks retry as explicitly
  **out of scope permanently**, not merely pending, per the user's own deferral ("tạm thời phần
  retry này làm động, khi nào cần tôi sẽ chỉ định sau") — so a later reader cannot mistake its
  absence for an oversight.
- `requirements.md`: 4 unresolved ⚠️ markers, each attached to the phase it blocks — the Keychain
  key string, the concrete timeout values, whether `details` needs surfacing, and whether `data`
  can be absent on success. Also records that `NetworkError.noData` is declared but never thrown
  anywhere today, and that Phase 1 must give it a real throw site or remove it.
- `design.md`: layers table separating **existing** rows from **new**/**modified** ones; the
  Go → Swift envelope mapping of the user's `ApiResponse` / `ErrorDetail` structs; a request
  lifecycle diagram; a Step-by-step Flow over one business request, spelling out the failure
  branches the current transport gets wrong (2xx with `success: false`, an unparseable error body,
  an absent `data`), since "decode the response" is otherwise one sentence hiding four outcomes.
- `design.md`: states explicitly that **both public `NetworkService` method signatures are
  unchanged** — the envelope is unwrapped inside the service, so no feature `Repository` written
  against today's API needs to change. This is what makes Phase 1 safe to land first.
- `design.md`: a "Deliberately deferred" section naming retry, 401 token refresh, multipart/form
  encoding, and a reachability pre-check — each stated as *not designed here* so none can be added
  silently as a side effect of the four phases.
- `tasks.md`: 5 phases ordered so Phase 1 (the envelope) comes first, because it is the one that
  unblocks feature work — a feature's `Repository` cannot map a failure to its own
  `IL<Feature>Error` until the transport can say *which* failure occurred. Phases 2–4 are real but
  nothing is blocked on them.
- `tasks.md`: a "Deferred" section (retry, 401 refresh, multipart, reachability, further file
  reorganisation) cross-referenced with the same items in `design.md`.
- Scope note recorded in all three files: this is an **infrastructure** spec under `Core/`, not a
  feature-scene spec — no Coordinator, no ViewModel, no navigation flow, no `DIContainer` feature
  section. `il-screen-builder` does not apply; the consuming side is `il-data-layer-builder`'s job.
- Reason for writing it: grep-verified gaps in the shipped transport, in the order they hurt —
  (1) no `Authorization` header or token provider of any kind; (2) `NetworkError.serverError`
  carries only a message, so two failures sharing a status code are indistinguishable; (3)
  `URLSession.shared` with no configured timeout or `waitsForConnectivity`; (4) no retry;
  (5) nothing in `Core/Networking` logs, despite `LoggingService` / `FlowTracker` /
  `CorrelationContext` all existing; (6) JSON only; (7) `NWPathMonitor` used solely by
  `MetricsCollector`; (8) `NetworkError.noData` declared but never thrown.
