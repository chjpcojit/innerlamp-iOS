# Tasks — GRPC

Version: 1.0
Last updated: 2026-09-28
Status: not started — prospective spec, no `Core/GRPC` code exists yet
Scope folder: `InnerLamp/Core/GRPC/`

> See `changelog.md` in this folder for the version history of this spec.

> Every item below traces back to a row in `design.md`'s "Layers & components" table or a step in
> one of its two Step-by-step Flow sections. Nothing here is invented. Every box starts `[ ]` —
> this is a prospective spec, nothing has been implemented yet.

> **Phase order is deliberate**, mirroring `Docs/Specs/Networking/tasks.md`'s rationale: the
> channel and auth (Phases 0-1) must exist before any call shape can be tested, and several tasks
> across phases are blocked on the same ⚠️ markers from `requirements.md` — those are called out
> inline, not silently worked around.

## Phase 0 — Dependency & environment groundwork (blocks everything else)

- [ ] Resolve the ⚠️ marker this phase depends on: verify `grpc-swift v2`'s minimum supported
      OS/Swift version against InnerLamp's `IPHONEOS_DEPLOYMENT_TARGET` (currently 26.5) — do not
      add the SPM dependency until this is checked
- [ ] Resolve the ⚠️ marker this phase depends on: pick and record the exact `grpc-swift v2`
      package version/tag to pin in `Package.swift` — record the choice in `changelog.md`, not
      just in the dependency graph
- [ ] Add the `grpc-swift v2` SPM dependency to the project
- [ ] Resolve the ⚠️ marker this phase depends on: obtain the concrete gRPC host(s)/port(s) for at
      least one environment (a placeholder/local value is acceptable to unblock Phase 1-4
      development, but must be recorded as a placeholder, not presented as real)

## Phase 1 — Channel & TLS (`FR-001`, `FR-003`, `FR-009`)

- [ ] Create `Core/GRPC/GRPCConfiguration.swift` — builds the one shared `GRPCClient`/channel,
      resolving host/port from `APIConfig.Environment`
- [ ] Extend `Core/Networking/APIConfig.swift`'s `Environment` with gRPC host/port fields —
      extending the existing config source, never a parallel one (`design.md` § Layers)
- [ ] Configure server-authenticated TLS only — confirm by code review that no client-certificate
      material is loaded or required anywhere in this file
- [ ] Register the shared channel in `DIContainer`, built once and held for the app's lifetime
- [ ] Tests: same channel instance is reused across multiple `Core/GRPC` calls in a test session
- [ ] `xcodebuild build` + `xcodebuild test` pass — report the real output

## Phase 2 — Auth metadata injection (`FR-002`)

- [ ] Create `Core/GRPC/GRPCAuthInterceptor.swift` — a `ClientInterceptor` reading the existing
      `AuthTokenProviding` protocol (`Core/Networking/AuthTokenProvider.swift`) — do not create a
      second token store or a second protocol
- [ ] Attach `authorization: Bearer <token>` as call-metadata when a token exists
- [ ] Handle the no-token path: send the call with no auth metadata — do not throw, do not block,
      do not fabricate an empty token
- [ ] Attach the interceptor to the shared channel built in Phase 1
- [ ] Tests (against the in-process test server from Phase 7): metadata present when a token
      exists; metadata absent when it does not; a token never appears unmasked anywhere in test
      log output
- [ ] `xcodebuild build` + `xcodebuild test` pass — report the real output

## Phase 3 — `GRPCError` mapping (`FR-005`, `FR-008`)

- [ ] Create `Core/GRPC/GRPCError.swift` — the enum mapping `GRPCStatus.Code` to named cases per
      `design.md` § "`GRPCError` — planned shape"
- [ ] Resolve the ⚠️ marker this phase depends on: whether a server-supplied error detail follows
      a structured convention analogous to `APIEnvelope`/`APIErrorDetail`, or gRPC's own
      `google.rpc.Status` details mechanism — do not invent a payload shape without a real
      `.proto` service to observe; if still unresolved when this phase starts, ship the
      status-code-only cases from the table and leave detail-carrying payloads as a documented gap
- [ ] Apply the default 30s deadline (`FR-008`, `NFR-001`) when a unary call specifies none
- [ ] Ensure no raw `grpc-swift` error type can leak past `Core/GRPC`'s public API — code review
      every public throw site
- [ ] Tests: each relevant `GRPCStatus.Code` (`.unauthenticated`, `.unavailable`,
      `.deadlineExceeded`, `.notFound`, `.internalError`, an unmapped code) produces the correct
      distinct `GRPCError` case
- [ ] Tests: a call exceeding the configured deadline throws the `.deadlineExceeded` case
- [ ] `xcodebuild build` + `xcodebuild test` pass — report the real output

## Phase 4 — Unary RPC support (`FR-004`)

- [ ] Create `Core/GRPC/GRPCService.swift` (naming TBD, see `design.md` ⚠️) — the unary method a
      feature Repository calls, wrapping the generated client stub
- [ ] Implement the full unary flow from `design.md` § "Step-by-step Flow — Unary RPC": build →
      auth metadata → execute with deadline → decode → log → return
- [ ] Tests against the in-process test server (Phase 7): success path decodes correctly; each
      failure branch from the flow throws the expected `GRPCError` case
- [ ] `xcodebuild build` + `xcodebuild test` pass — report the real output

## Phase 5 — Server-streaming RPC support (`FR-005`, `FR-006`)

- [ ] Add the server-streaming method to `GRPCService.swift`, returning an `AsyncSequence` per
      `design.md` § "Step-by-step Flow — Server-streaming RPC"
- [ ] Implement stream-open failure handling: a failure before any message is yielded throws the
      corresponding `GRPCError`, no partial/empty sequence is silently returned
- [ ] Implement in-order message decoding and yielding
- [ ] Implement the no-auto-reconnect guarantee (`FR-006`): a lost connection ends/throws on the
      stream; nothing in this layer attempts to resubscribe
- [ ] Resolve the ⚠️ marker this phase depends on (logging granularity — per-message vs
      per-stream-lifetime vs both) before finalizing `GRPCLogger`'s hook points for streams (see
      Phase 6)
- [ ] Tests against the in-process test server: multiple responses received in order for one
      logical call; a simulated stream interruption terminates the stream rather than silently
      retrying
- [ ] `xcodebuild build` + `xcodebuild test` pass — report the real output

## Phase 6 — Request/response logging (`FR-010`)

- [ ] Create `Core/GRPC/GRPCLogger.swift` — one record per completed unary RPC (and per the
      granularity resolved in Phase 5 for streams) through the existing `LoggingService`,
      containing method name, outcome (status code), and duration
- [ ] Route credential-shaped values (the bearer token) through `PIIMasker` before they reach any
      log destination
- [ ] Guarantee logging cannot change the outcome: a logging failure is swallowed and never turns
      a successful call into a thrown error — mirrors `Core/Networking`'s equivalent guarantee
- [ ] Attach the interceptor to the shared channel built in Phase 1
- [ ] Tests: one record per unary call; a bearer token never appears in the emitted record; a
      failed call logs the classification (the `GRPCError` case / status code), never raw
      response content
- [ ] `xcodebuild build` + `xcodebuild test` pass — report the real output

## Phase 7 — Build-time `.proto` codegen & in-process test server (`FR-011`, `FR-012`)

- [ ] Add an SPM build-tool plugin target wired for `.proto` → Swift codegen (`protoc-gen-swift` /
      the gRPC Swift codegen plugin) — confirm no generated Swift file needs to be manually
      created or committed
- [ ] Add a minimal test-only `.proto` service (unary + server-streaming methods) used solely by
      `InnerLampTests` — not a business contract, purely for exercising Phases 1-6's behavior
- [ ] Create the in-process (in-memory/localhost) test server conforming to that test-only
      service, using `grpc-swift`'s own testing utilities
- [ ] Wire every test written in Phases 1-6 to run against this server, with no network dependency
- [ ] Build verification: change the test `.proto` file and rebuild — confirm the stub regenerates
      without manual intervention
- [ ] Code review: confirm no generated Swift file is checked into git
- [ ] `xcodebuild build` + `xcodebuild test` pass — report the real output

## Phase 8 — Verification

- [ ] `git status` shows no edits outside `InnerLamp/Core/GRPC/` (plus the `APIConfig.Environment`
      extension and `DIContainer` channel registration from Phase 1, and `Package.swift` /
      project SPM dependency changes from Phase 0)
- [ ] Confirm no feature-layer file changed: `Domain/`, `Presentation/`, `Data/` untouched by this
      spec's work (no feature consumes `Core/GRPC` yet — see `requirements.md` Pending)
- [ ] Confirm `Core/Networking`'s public API is untouched — no signature in `NetworkService.swift`,
      `Endpoint.swift`, or `NetworkError.swift` changed as a side effect of this work
- [ ] Tick the boxes above that were genuinely completed in the same run — nothing else
- [ ] Append the `changelog.md` entry and bump the shared version across all three headers

## Deferred (specified elsewhere, not blocking this spec)

- **Client-streaming and bidirectional streaming** — not designed, not scoped. Needs its own spec
  revision if/when required.
- **Retry policy**, for any RPC — same deferral as `Docs/Specs/Networking/tasks.md`.
- **Automatic stream reconnection** — deliberately not added (`FR-006`).
- **Mutual TLS** — deliberately not added.
- **Keepalive-ping tuning for long-lived streams** — deferred until a real streaming consumer
  exists to prove it's needed (see `requirements.md` ⚠️ on `NFR-002`).
- **Any concrete business `.proto` service / RPC** — out of scope for this spec entirely; the
  first real consumer feature is not yet identified (see `requirements.md` Pending). When one is,
  it is `data-builder`'s job, following the same pattern that feature already uses for
  `Core/Networking`-backed Repositories.
