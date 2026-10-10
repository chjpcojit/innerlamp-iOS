# Software Requirements Specification — GRPC

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | GRPC (Core infrastructure layer) |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-09-28 |
| Status | draft — awaiting confirmation of open questions |
| Owner / author | ngthanhducit@gmail.com |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

> **Infrastructure spec, not a feature-scene spec.** There is no screen, no Coordinator, and no
> ViewModel here, so `ui-builder` does not apply to this layer itself. This document is the
> same kind of artifact as `Docs/Specs/Networking/SRS.md` (the existing REST transport spec) — it
> defines a new `Core/GRPC` transport boundary that feature Repositories may choose to use instead
> of, or alongside, `Core/Networking`.

---

## 1. Introduction

### 1.1 Purpose

This document specifies the requirements for a new **gRPC client core** (`Core/GRPC`) that gives
InnerLamp a second, reusable transport boundary for talking to backend services over gRPC —
mirroring the role `Core/Networking` already plays for REST. It is written for the engineering team
and drives `spec-writer`'s `requirements.md` / `design.md` / `tasks.md` for the `GRPC` scope
folder, and subsequently the actual `Core/GRPC` Swift implementation.

### 1.2 Scope

**In scope:**
- A shared, app-wide gRPC channel/client, built once and reused for every call (unary and
  streaming), analogous to `NetworkConfiguration`'s single `URLSession`.
- Unary (request/response) RPC support.
- Server-streaming RPC support (server sends a sequence of responses to one client request).
- Authentication via the existing Keychain-stored bearer access token, attached as gRPC
  call-metadata, reusing `AuthTokenProviding` — no new token store.
- TLS-secured channel (server-authenticated TLS, not mutual TLS).
- A `GRPCError` type that maps gRPC status codes and server error detail to a stable, Repository-
  consumable shape, mirroring `NetworkError`'s role for REST.
- Host/port/environment configuration, extending the existing `APIConfig` rather than introducing a
  parallel config source.
- Request/response logging through the existing `LoggingService` (via a gRPC interceptor), with
  credential-shaped data masked by `PIIMasker` — mirroring `NetworkLogger`.
- `.proto` → Swift code generation wired into the build via an SPM build-tool plugin, so generated
  stubs are never manually committed and never drift from the `.proto` source.
- An in-process (in-memory/localhost) test server usable from `XCTest`, so `Core/GRPC` can be unit
  tested without a real backend — mirroring how `NetworkServiceTests` uses `MockURLProtocol`.

**Out of scope (this revision):**
- **Client-streaming and bidirectional streaming.** Only server-streaming is a confirmed
  requirement; the other two streaming shapes are not requested and are not designed here.
- **Replacing `Core/Networking`.** REST stays exactly as-is for every feature already built (Login,
  SignUp, OTP, ForgotPassword, etc.). `Core/GRPC` is additive; Repositories choose per
  feature/endpoint which transport to use.
- **Mutual TLS / client certificates.** Only standard server-authenticated TLS is required.
- **Automatic stream reconnection.** A dropped server-streaming call ends; resubscribing (if
  desired) is the calling feature's decision, not this layer's.
- **Retry policy for any RPC**, unary or streaming — same deliberate deferral as the REST layer.
- **Any specific business service or `.proto` contract.** No concrete gRPC service is defined by
  this document; it specifies only the reusable client-side capability. The first real consumer
  feature is not yet identified (see § 2.7 and Appendix A).

### 1.3 Product overview

InnerLamp is a native iOS meditation/spiritual-practice app built with Clean Architecture,
Coordinator navigation, and MVVM. It already talks to its backend over a REST/JSON transport
(`Core/Networking`). This feature adds gRPC as a second transport option in `Core`, for future
backend services that are gRPC-native (e.g. anything requiring server-push/streaming, which REST's
request/response model does not support cleanly).

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| gRPC | Google Remote Procedure Call — an RPC framework using HTTP/2 and Protocol Buffers. |
| Protobuf / `.proto` | Protocol Buffers — the interface-definition language and binary wire format gRPC uses to describe services and messages. |
| Unary RPC | A single request, single response call — gRPC's equivalent of a REST request/response. |
| Server-streaming RPC | A single request that receives a sequence of responses from the server over one long-lived call. |
| Channel | The persistent HTTP/2 connection (and its configuration: TLS, keepalive, etc.) that RPC calls are made over. |
| Interceptor | A gRPC-swift hook that wraps every outgoing/incoming call, used here for auth-metadata injection and logging — the gRPC equivalent of `NetworkService`'s auth-header and logging steps. |
| `grpc-swift v2` | The gRPC Swift library major version selected for this layer, built for Swift structured concurrency. |
| Deadline | gRPC's per-call timeout concept — the equivalent of REST's request timeout. |

### 1.5 References

- `Docs/Specs/Networking/SRS.md`, `requirements.md`, `design.md` — the REST transport spec this
  layer is modeled after and coexists with.
- `Docs/Knowledge/architecture/networking.md` — the OKF concept for `Core/Networking`, which
  explicitly anticipated this: *"this keeps Domain and Presentation transport-agnostic, so a future
  gRPC migration is a Data-layer implementation swap, not a Domain/Presentation rewrite."*
- `InnerLamp/Domain/Repositories/ILLoginRepository.swift` — existing code comment stating the
  Repository abstraction is transport-agnostic by design ("implementation speaks HTTP, gRPC, or
  anything else").
- `AGENTS.md` — Clean Architecture / MVVM-C conventions this layer must respect (no UIKit in
  Domain/ViewModel; Core stays framework-boundary code).

### 1.6 Document organization

Section 2 describes how this layer fits into InnerLamp's existing architecture and what it assumes.
Section 3 is the full requirement set (interfaces, functional behavior, performance, data,
constraints, system attributes). Section 4 maps requirements to verification. Appendix A lists every
question this document could not resolve on its own.

---

## 2. Overall description

### 2.1 Product perspective

This is a **new, additive Core infrastructure layer**, not a replacement or enhancement of an
existing feature. It sits at the same architectural level as `Core/Networking`:

```
Feature Repository (Data layer)
        │
        ├──► Core/Networking  (REST — existing, unchanged)
        │
        └──► Core/GRPC        (new — this spec)
```

`Domain` and `Presentation` never import `Core/GRPC` directly, exactly as they never import
`Core/Networking` today — only a feature's `Repository` (Data layer) does, per the existing rule in
`Docs/Knowledge/architecture/networking.md`. It touches one external system: whatever gRPC-speaking
backend service(s) InnerLamp's server team stands up (none is contractually defined yet — see
Appendix A).

### 2.2 Product functions

- Provide one shared, app-wide gRPC channel/client for the whole app to issue RPCs over. (`FR-001`)
- Attach the existing Keychain access token to every RPC as call-metadata, mirroring REST's bearer
  auth. (`FR-002`)
- Support unary RPCs. (`FR-003`)
- Support server-streaming RPCs. (`FR-004`)
- Classify every RPC failure into a stable `GRPCError`, mirroring `NetworkError`. (`FR-005`)
- Configure the gRPC host/port per environment via `APIConfig`. (`FR-006`)
- Log every RPC (method, status, duration) through `LoggingService`, with PII masked. (`FR-007`)
- Generate Swift stubs from `.proto` sources automatically at build time. (`FR-008`)
- Provide an in-process test server so `Core/GRPC` is unit-testable without a live backend.
  (`FR-009`)

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| Feature developer | An InnerLamp engineer (or `data-builder`) implementing a Repository that needs to call a gRPC service. | Consumes `Core/GRPC`'s public API; never touches generated stub internals directly outside the Data layer. |
| End user (indirect) | The app's end user, indirectly affected via features built on top of this transport (e.g. faster real-time updates via streaming). | No direct interaction with this layer; it is purely infrastructure. |

### 2.4 Operating environment

- Platform: iOS, minimum version — same as the app's current deployment target
  (`IPHONEOS_DEPLOYMENT_TARGET` in `InnerLamp.xcodeproj`, currently 26.5). `grpc-swift v2`'s own
  minimum platform requirement must be checked against this at implementation time (see Appendix A).
- Devices: iPhone and iPad (same as the rest of the app).
- Network: online required for any RPC. No offline queuing or offline-first behavior is in scope,
  matching REST's current behavior.

### 2.5 Design and implementation constraints

- Must follow `AGENTS.md`'s Clean Architecture / MVVM-C rules: `Core/GRPC` is transport-boundary
  code; only a feature's Data-layer `Repository` may import it, exactly as only a Repository may
  import `Core/Networking` today.
- Must use Swift Concurrency (`async`/`await`, `actor`) idioms consistent with the rest of `Core`
  (e.g. `NetworkServiceImpl` is an `actor`).
- Built on **grpc-swift v2**.
- `.proto` → Swift codegen via an **SPM build-tool plugin** — no generated Swift committed to the
  repository.
- Auth token source of truth stays `AuthTokenProviding` / Keychain — this layer must not introduce a
  second token store.
- Host/port/environment configuration extends `Core/Networking/APIConfig.swift` rather than adding a
  parallel config file.
- No `IL` prefix on these types, matching the existing convention that `Core` infrastructure types
  (`NetworkService`, `Endpoint`, `APIConfig`) are unprefixed; `IL` is reserved for feature-layer
  types.

### 2.6 User documentation

**N/A** — this is an internal infrastructure layer with no end-user-facing documentation or UI.

### 2.7 Assumptions and dependencies

- **Assumptions:**
  - No `.proto` service contract exists yet; this spec defines only the generic, reusable transport
    capability (channel setup, auth, error mapping, logging, codegen pipeline, test harness) — not
    any concrete service or method.
  - `grpc-swift v2`'s minimum supported OS/Swift version is compatible with InnerLamp's current
    deployment target; this must be verified when the SPM dependency is actually added (flagged in
    Appendix A rather than asserted here as fact).
  - The backend team will expose a gRPC endpoint (host/port) reachable over TLS from the same
    environments (dev/staging/prod) the REST API already targets.
- **Dependencies:**
  - `Core/Networking/AuthTokenProvider.swift` (`AuthTokenProviding`) — reused, not duplicated, for
    the auth-metadata interceptor.
  - `Core/Networking/APIConfig.swift` — extended with gRPC host/port per environment.
  - `Core/Logging` (`LoggingService`, `PIIMasker`) — reused for the logging interceptor.
  - No dependency on `Core/Networking/NetworkService.swift` itself — the two transports are
    independent implementations that happen to share the auth/config/logging primitives above.

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

**N/A** — this is a Core infrastructure layer with no UI of its own. Any UI built on top of it
belongs to whichever feature later consumes a concrete gRPC service, and is out of scope here.

#### 3.1.2 Hardware interfaces

**N/A** — no custom hardware interface; this layer uses the device's standard network interfaces
exactly as `Core/Networking` does.

#### 3.1.3 Software interfaces

> ⚠️ Not confirmed: no `.proto` service/method contract exists yet — this section cannot list
> concrete RPC names, request/response message shapes, or gRPC status-code-to-business-meaning
> mappings until a backend service is defined. Blocks writing any concrete `FR-*` beyond the
> generic transport capability below.

At contract level, independent of any specific service:
- Transport: gRPC over HTTP/2, Protocol Buffers wire format.
- Call shapes supported: unary, server-streaming.
- Failure shape: gRPC status code (`GRPCStatus.Code`) plus optional server-supplied error detail,
  mapped to `GRPCError` (see `FR-005`).

#### 3.1.4 Communication interfaces

- Protocol: gRPC over HTTP/2, TLS-secured (server-authenticated TLS; not mutual TLS).
- Auth: `authorization: Bearer <token>` gRPC call-metadata, sourced from `AuthTokenProviding`
  (Keychain), attached per call by an interceptor.
- Host/port: per-environment values added to `APIConfig`'s `Environment`.
  > ⚠️ Not confirmed: the actual gRPC host(s)/port(s) for dev/staging/prod — blocks giving
  > `APIConfig` real values; a placeholder/local value would have to be used until the backend team
  > confirms this.

### 3.2 Functional requirements

#### Channel & connection

**FR-001 — Shared app-wide gRPC channel**
- **Priority:** Must
- **Description:** WHEN the app needs to make any gRPC call (unary or streaming), THE SYSTEM SHALL
  use a single, shared, long-lived `GRPCClient`/channel instance created once (at the composition
  root / `DIContainer`), rather than creating a new channel per call or per feature.
- **Verification method:** Unit test asserting the same channel instance is reused across multiple
  `Core/GRPC` calls in a test session; code review of `DIContainer` wiring.
- **Source:** User confirmation — "One shared channel, app-wide."

**FR-002 — Auth metadata injection**
- **Priority:** Must
- **Description:** WHEN an RPC is issued through `Core/GRPC` and a valid access token exists in the
  Keychain (via `AuthTokenProviding`), THE SYSTEM SHALL attach `authorization: Bearer <token>` as
  gRPC call-metadata to that call, without the caller declaring it explicitly.
- **Verification method:** Unit test against the in-process test server (`FR-009`) asserting the
  metadata is present when a token exists and absent when it does not.
- **Source:** User confirmation — "Reuse same token via gRPC metadata."

**FR-003 — TLS-secured channel**
- **Priority:** Must
- **Description:** WHEN the shared channel connects to the backend, THE SYSTEM SHALL use
  server-authenticated TLS. THE SYSTEM SHALL NOT present a client certificate (mutual TLS is out of
  scope).
- **Verification method:** Code review of channel/transport-security configuration; confirm no
  client-certificate material is loaded or required.
- **Source:** User confirmation — "Standard TLS only."

#### RPC call shapes

**FR-004 — Unary RPC support**
- **Priority:** Must
- **Description:** WHEN a feature Repository issues a unary call through `Core/GRPC`, THE SYSTEM
  SHALL send a single request and return a single decoded response (or throw a `GRPCError`),
  analogous to `NetworkService.request(endpoint:responseType:)`.
- **Verification method:** Unit test against the in-process test server.
- **Source:** Derived from scope (§1.2) and the REST layer's equivalent contract.

**FR-005 — Server-streaming RPC support**
- **Priority:** Must
- **Description:** WHEN a feature Repository issues a server-streaming call through `Core/GRPC`, THE
  SYSTEM SHALL expose the sequence of server responses as an `AsyncSequence` (or equivalent Swift
  Concurrency stream type) the caller can iterate with `for await`.
- **Verification method:** Unit test against the in-process test server, asserting multiple
  responses are received in order for one logical call.
- **Source:** User confirmation — "Needs streaming support now" / "Server-streaming."

**FR-006 — No automatic stream reconnection**
- **Priority:** Must
- **Description:** WHEN an active server-streaming call's underlying connection is lost (app
  backgrounded, network dropped, etc.), THE SYSTEM SHALL end/throw on that stream and SHALL NOT
  automatically attempt to resubscribe or reconnect. Resubscription, if desired, is the calling
  feature's own decision.
- **Verification method:** Unit test simulating a stream interruption against the in-process test
  server, asserting the stream terminates rather than silently retrying.
- **Source:** User confirmation — "No auto-reconnect — stream just ends, caller decides."

#### Error handling

**FR-007 — `GRPCError` mapping**
- **Priority:** Must
- **Description:** WHEN any RPC (unary or streaming) fails, THE SYSTEM SHALL surface a `GRPCError`
  value that carries at minimum the gRPC status code and any server-supplied error detail, so a
  feature's Repository can map it to its own `IL<Feature>Error` the same way it maps `NetworkError`
  today. THE SYSTEM SHALL NOT let a raw `grpc-swift` library error type leak past `Core/GRPC`'s
  public API.
- **Verification method:** Unit test asserting each relevant gRPC status code (`.unauthenticated`,
  `.unavailable`, `.deadlineExceeded`, `.notFound`, `.internalError`, etc.) maps to a distinct,
  named `GRPCError` case.
- **Source:** User confirmation — "New GRPCError enum, mirrored to NetworkError."

**FR-008 — Deadline**
- **Priority:** Must
- **Description:** WHEN a unary RPC is issued and no per-call deadline is explicitly specified, THE
  SYSTEM SHALL apply a default deadline of 30 seconds, matching `NetworkConfiguration`'s existing
  REST request timeout.
- **Verification method:** Unit test asserting a call exceeding the configured deadline throws the
  `GRPCError` case corresponding to `.deadlineExceeded`.
- **Source:** User confirmation — "Same as REST (30s), retry deferred."

#### Configuration

**FR-009 — Environment-based host configuration**
- **Priority:** Must
- **Description:** WHEN the shared channel is constructed, THE SYSTEM SHALL resolve the gRPC
  host/port from `APIConfig`'s `Environment`, the same mechanism REST's `serverBaseURL` uses, so
  switching environments (dev/staging/prod) changes both transports consistently.
- **Verification method:** Code review; unit test asserting the channel is built with the host/port
  matching the active `Environment`.
- **Source:** User confirmation — "Extend APIConfig."
  > ⚠️ Not confirmed: the concrete host/port values per environment (see §3.1.4) — blocks giving
  > `APIConfig` real, non-placeholder values.

#### Observability

**FR-010 — Request/response logging**
- **Priority:** Must
- **Description:** WHEN an RPC (unary call, or each message/completion of a streaming call)
  completes, THE SYSTEM SHALL emit a log record through `LoggingService` containing the method name,
  outcome (status code), and duration, via a gRPC client interceptor mirroring `NetworkLogger`'s
  role. WHEN any logged data is credential-shaped (the bearer token, any password-like field), THE
  SYSTEM SHALL route it through `PIIMasker` before it reaches any log destination.
- **Verification method:** Unit test asserting a `LoggingService` record is produced for a
  successful and a failed call against the in-process test server, and that the auth-metadata value
  never appears unmasked in the record.
- **Source:** User confirmation — "Yes, mirror NetworkLogger via an interceptor."

#### Build & codegen

**FR-011 — Build-time `.proto` codegen**
- **Priority:** Must
- **Description:** WHEN a `.proto` file is added or changed in the project, THE SYSTEM SHALL
  regenerate the corresponding Swift message/service stubs automatically as part of the Xcode/SPM
  build, via an SPM build-tool plugin (`protoc-gen-swift` / the gRPC Swift codegen plugin). THE
  SYSTEM SHALL NOT require generated Swift files to be manually created or committed to the
  repository.
- **Verification method:** Build verification — changing a `.proto` file and rebuilding regenerates
  the stub without manual intervention; code review confirming no generated file is checked in.
- **Source:** User confirmation — "SPM build plugin, generated at build time."

#### Testing

**FR-012 — In-process test server**
- **Priority:** Must
- **Description:** WHEN `Core/GRPC` behavior needs to be unit tested (auth injection, error mapping,
  logging, streaming), THE SYSTEM SHALL provide (or the test target SHALL set up) an in-process
  (in-memory or localhost) gRPC test server conforming to a generated test-only service, so tests
  exercise real wire/serialization/interceptor behavior without depending on a live backend —
  mirroring `NetworkServiceTests`'s use of `MockURLProtocol`.
- **Verification method:** The test suite itself is the verification; CI runs it with no network
  dependency.
- **Source:** User confirmation — "In-process test server via grpc-swift's testing utilities."

### 3.3 Performance requirements

- **NFR-001 — Default unary deadline:** A unary RPC with no explicit deadline SHALL time out at 30
  seconds (matches `FR-008` / REST's existing timeout).
- **NFR-002 — Channel reuse overhead:** Reusing the shared channel (`FR-001`) for a new call SHALL
  NOT re-establish a new TLS/HTTP-2 connection per call; connection setup happens once (or on
  reconnect after a hard failure), not per RPC.
  > ⚠️ Not confirmed: whether specific keepalive-ping settings (interval/timeout) are required to
  > keep a long-lived server-streaming call alive through NAT/proxy idle timeouts — not raised by
  > the user; left as an implementation-time decision unless it proves necessary.

### 3.4 Logical database requirements

- No new local persistence is introduced by this layer. The access token it reads already lives in
  the Keychain (`AuthTokenProviding` — no new key, no new store).
- No data is cached or persisted by `Core/GRPC` itself; any caching of streamed data is a concern for
  whichever feature consumes a concrete streaming RPC later, not this layer.

### 3.5 Design constraints

- Must be built on `grpc-swift v2`.
- Must use an SPM build-tool plugin for `.proto` codegen (`FR-011`) — no manual/checked-in generated
  code.
- Must not introduce a second auth-token store; must reuse `AuthTokenProviding`.
- Must not violate the `AGENTS.md` rule that only a feature's Data-layer `Repository` may import
  transport-layer code — `Domain`/`Presentation` never import `Core/GRPC` directly.
- Naming: no `IL` prefix on `Core/GRPC` types, consistent with `Core/Networking`.

### 3.6 Software system attributes

- **Reliability:** No retry policy (deliberately deferred, matching REST); a failed RPC surfaces
  immediately as `GRPCError` and the caller decides what to do. A dropped stream ends rather than
  silently hanging (`FR-006`).
- **Availability:** Single shared channel; if the channel is in a broken state, calls fail with a
  `GRPCError` mapping `.unavailable` rather than hanging indefinitely (bounded by the deadline,
  `FR-008`).
- **Security:** TLS-only channel (`FR-003`, no plaintext transport); auth token sourced from Keychain
  and never logged unmasked (`FR-010`); no new PII surface introduced beyond what REST already
  handles via the same token.
- **Maintainability:** Generated stubs are never hand-edited (build-time codegen, `FR-011`); `Core`
  stays the single place either transport's cross-cutting concerns (auth, logging, config) live, so
  a feature Repository's code is the same shape regardless of which transport it picks.
- **Portability:** N/A beyond standard iOS/iPadOS support already assumed by the rest of the app.

---

## 4. Verification & traceability

### 4.1 Verification approach

Every `FR-*`/`NFR-*` above lists its own verification method. The dominant method is a unit test run
against the in-process test server (`FR-012`) — this avoids any dependency on a live backend, which
does not exist yet for this layer. Two items (`FR-011`'s codegen and `FR-003`'s TLS configuration)
are verified by build behavior and code review rather than a runtime test, since they are structural
/ configuration guarantees.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | User: shared channel | → spec-writer | TBD |
| FR-002 | User: reuse Keychain token via metadata | → spec-writer | TBD |
| FR-003 | User: standard TLS only | → spec-writer | TBD |
| FR-004 | Derived from scope / REST parity | → spec-writer | TBD |
| FR-005 | User: server-streaming required | → spec-writer | TBD |
| FR-006 | User: no auto-reconnect | → spec-writer | TBD |
| FR-007 | User: GRPCError mirroring NetworkError | → spec-writer | TBD |
| FR-008 | User: 30s default deadline, retry deferred | → spec-writer | TBD |
| FR-009 | User: extend APIConfig | → spec-writer | TBD |
| FR-010 | User: mirror NetworkLogger via interceptor | → spec-writer | TBD |
| FR-011 | User: SPM build plugin codegen | → spec-writer | TBD |
| FR-012 | User: in-process test server | → spec-writer | TBD |
| NFR-001 | User: 30s default deadline | → spec-writer | TBD |
| NFR-002 | Derived from FR-001 (channel reuse) | → spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: no `.proto` service/method contract exists yet — blocks writing any concrete
> `FR-*` for a real business RPC beyond the generic transport capability (§3.1.3).

> ⚠️ Not confirmed: the concrete gRPC host(s)/port(s) for dev/staging/prod environments — blocks
> giving `APIConfig`'s gRPC extension (`FR-009`) real, non-placeholder values.

> ⚠️ Not confirmed: `grpc-swift v2`'s minimum supported OS/Swift version has not been checked
> against InnerLamp's current deployment target (`IPHONEOS_DEPLOYMENT_TARGET = 26.5`) — should be
> verified before or during `spec-writer`'s design phase, when the SPM dependency is actually
> added.

> ⚠️ Not confirmed: which feature will be the first real consumer of server-streaming (`FR-005`) —
> not tied to a specific feature yet. This does not block building the reusable `Core/GRPC` capability
> itself, but it does mean there is no end-to-end example to validate the streaming API's ergonomics
> against until one exists.

> ⚠️ Not confirmed: whether long-lived server-streaming calls need explicit gRPC keepalive-ping
> tuning to survive NAT/proxy idle timeouts (see NFR-002) — not raised by the user; may need
> revisiting once a real streaming consumer exists.

> ⚠️ Not confirmed: exact `grpc-swift v2` package version/tag to pin in `Package.swift` — left to
> implementation time; not a business decision but should not be silently picked without recording
> it in `design.md`.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Should this layer replace REST or coexist with it? | Coexist — `Core/Networking` stays for all existing features; `Core/GRPC` is additive, chosen per feature/endpoint. | 2026-09-28 |
| Does a `.proto` contract already exist? | No — this spec covers only the reusable client-side transport core, no concrete service. | 2026-09-28 |
| Which Swift gRPC library? | `grpc-swift v2`. | 2026-09-28 |
| How does gRPC auth relate to REST's bearer token? | Same token, reused via `AuthTokenProviding`, attached as gRPC call-metadata. | 2026-09-28 |
| TLS or mTLS? | Standard server-authenticated TLS only; no client certificates. | 2026-09-28 |
| Is streaming needed now? | Yes — server-streaming specifically; client-streaming and bidirectional are out of scope for this revision. | 2026-09-28 |
| How are gRPC failures surfaced to Repositories? | A new `GRPCError` type mirroring `NetworkError`'s role and shape. | 2026-09-28 |
| Where does gRPC host/port config live? | Extends the existing `APIConfig` (same `Environment` mechanism as REST). | 2026-09-28 |
| Should gRPC calls be logged like REST calls? | Yes — an interceptor mirrors `NetworkLogger`, routing through `LoggingService` and `PIIMasker`. | 2026-09-28 |
| What is the default deadline, and is retry in scope? | 30s default deadline (matches REST); retry policy explicitly deferred, same stance as `Docs/Specs/Networking`. | 2026-09-28 |
| How are `.proto` files compiled to Swift? | SPM build-tool plugin, generated at build time — nothing committed to git. | 2026-09-28 |
| Is the channel shared or per-call? | One shared, app-wide channel, built once (composition root). | 2026-09-28 |
| How is a dropped streaming connection handled? | No auto-reconnect — the stream ends and the calling feature decides whether to resubscribe. | 2026-09-28 |
| How is this layer unit-tested without a live server? | An in-process test server via `grpc-swift`'s own testing utilities, mirroring `MockURLProtocol`'s role for REST. | 2026-09-28 |
