# Design — GRPC

Version: 1.0
Last updated: 2026-09-28
Status: not started — prospective spec, no `Core/GRPC` code exists yet
Scope folder: `InnerLamp/Core/GRPC/`

> See `changelog.md` in this folder for the version history of this spec.

> **Prospective throughout.** Every row in the Layers table below is planned, not shipped — there
> is no `Core/GRPC` folder, no gRPC entry in `InnerLamp.xcodeproj/project.pbxproj`, and no `grpc-swift`
> SPM dependency today (verified by search before writing this spec).

> This is an infrastructure spec, not a feature-scene spec. There is no Coordinator, no ViewModel,
> no navigation flow, and no `DIContainer` *feature* factory to add — only a Core-level client
> registration. `ui-builder` does not apply. The consuming side — a feature's `Repository`
> calling `Core/GRPC` — is `data-builder`'s job, and cannot start until a `.proto` contract
> exists (see `requirements.md` Pending).

## Overview

`Core/GRPC` becomes a second transport boundary alongside `Core/Networking`, at the same
architectural level:

```
Feature Repository (Data layer)
        │
        ├──► Core/Networking  (REST — existing, unchanged)
        │
        └──► Core/GRPC        (new — this spec)
```

`Domain` and `Presentation` never import `Core/GRPC` directly, exactly as they never import
`Core/Networking` today — only a feature's `Repository` does. This spec builds the reusable
capability in the priority order the SRS confirms:

1. **Channel + TLS** — one shared, app-wide `GRPCClient` built at the composition root, connecting
   over server-authenticated TLS.
2. **Auth metadata injection** — attach the existing Keychain bearer token via an interceptor,
   reusing `AuthTokenProviding` — no second token store.
3. **Unary + server-streaming call support** — the two confirmed RPC shapes, both async/await-
   native.
4. **`GRPCError` mapping** — a stable, Repository-consumable failure shape, mirroring
   `NetworkError`.
5. **Logging** — one record per RPC through the existing `LoggingService`, via an interceptor
   mirroring `NetworkLogger`.
6. **`.proto` → Swift codegen** — an SPM build-tool plugin, no generated code committed.
7. **In-process test server** — for unit-testing the above without a live backend.

**No concrete `.proto` service is designed here.** Every layer below is generic transport
capability; the first business RPC is a separate spec once a contract exists (see
`requirements.md` Pending).

## Layers & components

| Layer | File | Status | Responsibility |
|---|---|---|---|
| Channel | `Core/GRPC/GRPCConfiguration.swift` | **new** | Builds the one `GRPCClient`/channel the app uses: host/port resolved from `APIConfig.Environment` (`FR-009`), TLS transport security configured (server-authenticated only, `FR-003`), default deadline of 30s applied when a call doesn't specify one (`FR-008`). |
| Auth | `Core/GRPC/GRPCAuthInterceptor.swift` | **new** | A `ClientInterceptor` that reads `AuthTokenProviding` (the same protocol `Core/Networking/AuthTokenProvider.swift` defines) and attaches `authorization: Bearer <token>` as call-metadata when a token exists (`FR-002`). Introduces no new token store. |
| Errors | `Core/GRPC/GRPCError.swift` | **new** | `GRPCError` enum mapping `GRPCStatus.Code` (and any server-supplied error detail) to named, Repository-consumable cases — the gRPC equivalent of `Core/Networking/NetworkError.swift` (`FR-005`). No raw `grpc-swift` error type may cross this boundary. |
| Observability | `Core/GRPC/GRPCLogger.swift` | **new** | A `ClientInterceptor` that turns one completed RPC (or one message/completion of a stream) into a `LoggingService` record — method name, status, duration — mirroring `Core/Networking/NetworkLogger.swift`. Routes credential-shaped values through `PIIMasker` first (`FR-010`). |
| Transport / client | `Core/GRPC/GRPCService.swift` (naming TBD at implementation — see ⚠️ below) | **new** | The app-facing entry point a Repository calls: a unary method returning a single decoded response or throwing `GRPCError`, and a server-streaming method returning an `AsyncSequence` of decoded responses (`FR-004`, `FR-005`). Wraps the generated (codegen'd) client stub; never exposes it directly. |
| Host config | `Core/Networking/APIConfig.swift` | **modified** | Extended with gRPC host/port per `Environment`, alongside REST's existing `serverBaseURL` — not a parallel config file (`FR-009`). |
| Codegen | SPM build-tool plugin target (exact plugin package TBD — see ⚠️ below) | **new** | Regenerates Swift message/service stubs from `.proto` sources on every build; nothing generated is committed (`FR-011`). |
| Testing | `InnerLampTests/GRPC/GRPCTestServer.swift` (or similar — TBD once a test-only `.proto` exists) | **new** | An in-process (in-memory/localhost) gRPC server used only by `XCTest`, so `Core/GRPC`'s auth/error/logging/streaming behavior can be verified without a live backend (`FR-012`). |

**Naming:** none of these types carry an `IL` prefix, matching `Core/Networking`'s convention —
`IL` is reserved for feature-layer types.

> ⚠️ Not confirmed: exact file/type names above (`GRPCService`, the codegen plugin target's name)
> are placeholders chosen to fit this spec's naming convention — not confirmed by the user. They
> should be finalized at implementation time against whatever `grpc-swift v2`'s own generated-code
> conventions require, and recorded here (bump version) once fixed rather than silently renamed in
> code without updating this table.

## No caller-visible dependency on `Core/Networking`

`Core/GRPC` shares exactly three things with `Core/Networking`, all by reuse, not duplication:

| Shared primitive | Source | Reused for |
|---|---|---|
| `AuthTokenProviding` | `Core/Networking/AuthTokenProvider.swift` | Reading the same Keychain-stored bearer token (`FR-002`) |
| `APIConfig` / `Environment` | `Core/Networking/APIConfig.swift` | Resolving gRPC host/port per environment (`FR-009`) |
| `LoggingService`, `PIIMasker` | `Core/Logging/` | Emitting masked RPC log records (`FR-010`) |

`Core/GRPC` does **not** depend on `Core/Networking/NetworkService.swift`, `Endpoint`, or
`NetworkError` — the two transports are independent implementations that happen to share the
auth/config/logging primitives above, per SRS §2.7.

## Channel lifecycle (this spec's equivalent of a navigation flow)

```
DIContainer (composition root)
  │  build once, held for the app's lifetime
  ▼
GRPCConfiguration.makeChannel()
  │
  ├─ 1. resolve host/port          (APIConfig.Environment — FR-009)
  ├─ 2. configure TLS               (server-authenticated only — FR-003)
  ├─ 3. attach interceptors         (GRPCAuthInterceptor, GRPCLogger — FR-002, FR-010)
  └─ 4. return shared GRPCClient    (held app-wide — FR-001)

Feature Repository
  │  IL<Feature>Mapper.toRequest(entity) → generated proto request message
  ▼
GRPCService.unary(...) / .serverStream(...)
  uses the shared GRPCClient from step 4 above — never builds its own channel
```

## Step-by-step Flow — Unary RPC, end to end

Spelled out for the same reason `Docs/Specs/Networking/design.md`'s equivalent section exists:
"send a request, get a response" hides several distinct outcomes (auth injection, deadline,
status-code mapping) that must not be assumed away.

```
Step 1 — Build the call
- Trigger: a feature Repository calls GRPCService's unary method with a generated
  request message
- Pre-condition: the shared GRPCClient (channel) already exists (built once, at
  DIContainer)
- Effect: pass the request through the shared channel, using the interceptor chain
  configured on it

Step 2 — Inject the auth metadata
- Trigger: Step 1's call enters GRPCAuthInterceptor
- Pre-condition: AuthTokenProviding reads the Keychain
- Effect: a token exists → attach "authorization: Bearer <token>" as call-metadata
    - No token stored → send the call with no auth metadata. Do not throw, do not
      block, do not fabricate an empty token — mirrors Core/Networking Step 2's
      no-token path (design.md, Networking spec)

Step 3 — Execute with deadline
- Trigger: metadata attached
- Effect: the call executes against the shared channel
    - No explicit deadline specified by the caller → apply the 30s default
      (FR-008, NFR-001)
    - Deadline exceeded → throw the GRPCError case mapping .deadlineExceeded
    - Channel unavailable → throw the GRPCError case mapping .unavailable
    - Any other non-OK GRPCStatus.Code → throw the corresponding named GRPCError case
    - OK → Step 4

Step 4 — Decode the response
- Trigger: GRPCStatus.Code == .ok
- Effect: decode the generated proto response message into the type the caller
  requested
    - Decode succeeds → Step 5
    - Decode fails → throw the GRPCError case for a malformed response (exact
      GRPCError case shape TBD at implementation — see design note on GRPCError below)

Step 5 — Log
- Trigger: the call has concluded, successfully or not
- Effect: GRPCLogger emits exactly one record through LoggingService containing the
  method name, outcome (status code), and duration (FR-010)
    - Anything credential-shaped (bearer token) goes through PIIMasker first
    - Logging failure is swallowed; it never turns a successful call into a thrown
      error — mirrors Core/Networking's logging guarantee

Step 6 — Return
- Trigger: Steps 4-5 done
- Effect: return the decoded response to the Repository, or throw the GRPCError from
  Steps 3-4. The Repository maps GRPCError → IL<Feature>Error
  (data-builder's job, out of scope here)
```

## Step-by-step Flow — Server-streaming RPC, end to end

```
Step 1 — Build the call
- Trigger: a feature Repository calls GRPCService's server-streaming method with a
  generated request message
- Pre-condition: same shared GRPCClient as the unary flow

Step 2 — Inject the auth metadata
- Same as unary Step 2 — one metadata attachment for the whole streaming call, not
  per message

Step 3 — Open the stream
- Trigger: metadata attached
- Effect: the call opens against the shared channel and returns an AsyncSequence the
  Repository iterates with `for await` (FR-005)
    - Open fails (e.g. .unavailable, .unauthenticated) → throw the corresponding
      GRPCError case before any message is yielded
    - Open succeeds → Step 4

Step 4 — Receive messages
- Trigger: the server sends each response message
- Effect: decode and yield each message in order through the AsyncSequence
    - A message fails to decode → the sequence throws the GRPCError case for a
      malformed response; the stream ends there, no further messages are yielded
    - The server closes the stream normally (GRPCStatus.Code == .ok) → the
      AsyncSequence finishes normally, no error
    - The underlying connection is lost (network drop, app backgrounded) → the
      sequence throws; THE SYSTEM SHALL NOT automatically resubscribe (FR-006).
      Resubscription, if desired, is the calling feature's own decision — a fresh
      call to Step 1, not a resume of this one

Step 5 — Log
- Trigger: the stream ends, successfully or not, or on each message (TBD — see ⚠️
  below)
- Effect: GRPCLogger emits log record(s) through LoggingService, mirroring the unary
  flow's Step 5 guarantees (masked credentials, swallowed logging failures)
```

> ⚠️ Not confirmed: whether a server-streaming call logs one record per message received, one
> record for the whole stream's lifetime, or both — the SRS (`FR-010`) says "each message/completion
> of a streaming call" without picking one. Left as an implementation-time decision unless the user
> specifies otherwise; should favor whichever produces useful `LoggingService` signal without
> flooding it for a high-frequency stream.

## `GRPCError` — planned shape

Mirrors `NetworkError`'s role (`Core/Networking/NetworkError.swift`): a Swift enum with one case
per meaningfully distinct failure a Repository needs to discriminate, never a passthrough of the
underlying library's error type.

| gRPC `GRPCStatus.Code` | Planned `GRPCError` case | Notes |
|---|---|---|
| `.unauthenticated` | `.unauthenticated` | No token, or token rejected by the server — the gRPC analogue of REST's `.unauthorized`. No token-refresh is attempted here, same deferral as `Core/Networking`. |
| `.unavailable` | `.unavailable` | Channel/server unreachable — analogue of `.noInternetConnection` / a REST 5xx that never reached the app. |
| `.deadlineExceeded` | `.deadlineExceeded` | The 30s default (or an explicit caller deadline) elapsed — analogue of `.timeout`. |
| `.notFound` | `.notFound` | Analogue of a REST 404. |
| `.internalError` | `.serverError` | Analogue of `.serverError(statusCode:message:)` — exact payload (message string, structured detail) TBD, see ⚠️ below. |
| any other non-OK code | `.unknown(code:)` (or similar catch-all) | Mirrors `NetworkError.unknown(_:)`'s role as a safety net for a code this layer doesn't name individually. |
| response fails to decode | `.decodingError` (or similar) | Mirrors `NetworkError.decodingError`. |

> ⚠️ Not confirmed: whether a gRPC "server-supplied error detail" (SRS §3.1.3 — "gRPC status code
> plus optional server-supplied error detail") follows a structured convention analogous to
> `Core/Networking`'s `APIEnvelope`/`APIErrorDetail` (a JSON-like `details` map surfaced per case,
> the way `NetworkError.apiError(code:message:type:details:)` does), or whether gRPC's own
> `google.rpc.Status` `details` mechanism is used directly. This cannot be resolved until a real
> `.proto` service exists to observe the backend's actual error convention — blocks finalizing
> `GRPCError`'s exact case payloads (only the case names above are reasonably confident).

## Deliberately deferred (in this spec, not implemented)

Named so a future reader does not mistake their absence for an oversight, mirroring
`Docs/Specs/Networking/design.md`'s equivalent section:

- **Client-streaming and bidirectional streaming.** Not designed here — only server-streaming is
  built. Adding either later needs its own spec revision, not a mechanical extension of
  `GRPCService`.
- **Retry policy**, for any RPC. Same deliberate deferral as `Core/Networking`
  (`Docs/Specs/Networking/design.md` § "Deliberately deferred").
- **Automatic stream reconnection.** A dropped stream ends (`FR-006`); resubscribing is the
  calling feature's decision, not this layer's.
- **Mutual TLS.** Only server-authenticated TLS is configured; no client-certificate loading exists
  anywhere in this design.
- **Keepalive-ping tuning** for long-lived streams. Not configured until a real streaming consumer
  proves it's needed — see the ⚠️ under `requirements.md` Pending (NFR-002).

## Architecture note — why this coexists with `Core/Networking` rather than replacing it

Recorded here because `Docs/Specs/Networking/design.md` already anticipated this migration
direction (its own "Architecture note — transport-agnosticism" section) and named exactly which
REST-specific primitives would need a gRPC-shaped replacement rather than reuse:

| REST primitive (`Core/Networking`) | gRPC replacement (this spec) | Reused as-is? |
|---|---|---|
| `Endpoint` (path, method, query) | Generated proto request message + `GRPCService` method | No — different shape entirely |
| `APIEnvelope` (`success`/`data`/`error`) | `GRPCStatus.Code` + optional server error detail → `GRPCError` | No — same *pattern* (one discriminated failure type before the Repository sees it), different type |
| Auth header injection | `GRPCAuthInterceptor` metadata injection | Policy reused (`AuthTokenProviding`, explicit-value-wins semantics where applicable); mechanism is not |
| `NetworkConfiguration`'s `URLSessionConfiguration` | `GRPCConfiguration`'s channel/TLS/deadline config | No — no `URLSession` equivalent exists in gRPC |
| `NetworkLogger`'s fields (method, path, status, duration) | `GRPCLogger`'s fields (method, status, duration) | Same responsibility, different field set (no "path" concept in gRPC) |

Net effect, confirmed by the SRS: this is **additive**, not a migration. `Core/Networking` is
unchanged; a feature's Repository picks per endpoint which transport it speaks. Nothing in this
design assumes or plans for REST being removed.

## Verification approach

`Core/GRPC` has no code today, so there is no existing test file to extend. Per `FR-012`, every
phase in `tasks.md` that adds behavior also adds coverage for it, run against the in-process test
server (never a live backend) — mirroring `Core/Networking`'s `NetworkServiceTests` /
`MockURLProtocol` pattern. The auth-metadata matrix (token present / absent) and the `GRPCError`
status-code mapping matter most, since they are what a feature's Repository will build its own
error-mapping logic against, the same way `NetworkError`'s cases do for REST today.
