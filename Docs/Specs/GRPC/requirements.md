# Requirements — GRPC

Version: 1.0
Last updated: 2026-09-28
Status: not started — prospective spec, no `Core/GRPC` code exists yet
Scope folder: `InnerLamp/Core/GRPC/`

> See `changelog.md` in this folder for the version history of this spec.

> **Prospective spec** — written before any code exists. Generated from `Docs/Specs/GRPC/SRS.md`
> (`ba-writer`'s IEEE 29148 SRS), which is the authoritative source for every requirement and every
> ⚠️ below. Nothing here resolves an ⚠️ that the SRS left open.

> This is an infrastructure spec, not a feature-scene spec. There is no screen, no Coordinator, and
> no ViewModel here — so `ui-builder` does not apply. It is the same kind of artifact as
> `Docs/Specs/Networking/`, the REST transport spec this layer is additive to. The consuming side
> (a feature `Repository` calling `Core/GRPC` instead of, or alongside, `Core/Networking`) is
> `data-builder`'s job once a concrete `.proto` service exists — see Pending.

## User Story

As an InnerLamp feature developer, I want a reusable `Core/GRPC` transport boundary — with a shared
channel, auth-metadata injection, unary and server-streaming call support, and error/log mapping
mirroring `Core/Networking` — so that when a gRPC-native backend service is ready, I can build its
`Repository` against a settled transport instead of inventing channel setup, auth, and error
handling per feature.

## Acceptance Criteria (EARS notation)

### Channel

- WHEN the app needs to make any gRPC call (unary or server-streaming), THE SYSTEM SHALL use a
  single, shared, long-lived channel/client instance built once at the composition root
  (`DIContainer`), rather than a new channel per call or per feature.
- WHEN the shared channel connects to the backend, THE SYSTEM SHALL use server-authenticated TLS.
  THE SYSTEM SHALL NOT present a client certificate (mutual TLS is out of scope).

### Auth

- WHEN an RPC is issued through `Core/GRPC` and a valid access token exists in the Keychain (via
  `AuthTokenProviding`), THE SYSTEM SHALL attach `authorization: Bearer <token>` as gRPC
  call-metadata to that call, without the caller declaring it explicitly — reusing the same
  `AuthTokenProviding` protocol `Core/Networking` uses, not a second token store.

### RPC call shapes

- WHEN a feature Repository issues a unary call through `Core/GRPC`, THE SYSTEM SHALL send a single
  request and return a single decoded response, or throw a `GRPCError` — analogous to
  `NetworkService.request(endpoint:responseType:)`.
- WHEN a feature Repository issues a server-streaming call through `Core/GRPC`, THE SYSTEM SHALL
  expose the sequence of server responses as an `AsyncSequence` (or equivalent Swift Concurrency
  stream type) the caller iterates with `for await`.
- WHEN an active server-streaming call's underlying connection is lost, THE SYSTEM SHALL end/throw
  on that stream. THE SYSTEM SHALL NOT automatically attempt to resubscribe or reconnect —
  resubscription, if desired, is the calling feature's own decision.
- Client-streaming and bidirectional-streaming RPC shapes are explicitly **out of scope** for this
  revision — see "Out of scope" below.

### Error handling

- WHEN any RPC (unary or streaming) fails, THE SYSTEM SHALL surface a `GRPCError` value carrying at
  minimum the gRPC status code and any server-supplied error detail, mirroring how `NetworkError`
  surfaces a REST failure, so a feature's Repository can map it to its own `IL<Feature>Error` the
  same way it maps `NetworkError` today. THE SYSTEM SHALL NOT let a raw `grpc-swift` library error
  type leak past `Core/GRPC`'s public API.
- WHEN a unary RPC is issued and no per-call deadline is explicitly specified, THE SYSTEM SHALL
  apply a default deadline of 30 seconds, matching `NetworkConfiguration`'s existing REST request
  timeout.

### Configuration

- WHEN the shared channel is constructed, THE SYSTEM SHALL resolve the gRPC host/port from
  `APIConfig`'s `Environment`, the same mechanism REST's `serverBaseURL` uses, so switching
  environments (dev/staging/prod) changes both transports consistently.

### Observability

- WHEN an RPC (unary call, or each message/completion of a streaming call) completes, THE SYSTEM
  SHALL emit a log record through `LoggingService` containing the method name, outcome (status
  code), and duration, via a gRPC client interceptor mirroring `NetworkLogger`'s role.
- WHEN any logged data is credential-shaped (the bearer token, any password-like field), THE SYSTEM
  SHALL route it through `PIIMasker` before it reaches any log destination.

### Build & codegen

- WHEN a `.proto` file is added or changed in the project, THE SYSTEM SHALL regenerate the
  corresponding Swift message/service stubs automatically as part of the Xcode/SPM build, via an
  SPM build-tool plugin. THE SYSTEM SHALL NOT require generated Swift files to be manually created
  or committed to the repository.

### Testing

- WHEN `Core/GRPC` behavior needs to be unit tested (auth injection, error mapping, logging,
  streaming), THE SYSTEM SHALL provide an in-process (in-memory or localhost) gRPC test server
  conforming to a generated test-only service, so tests exercise real wire/serialization/interceptor
  behavior without depending on a live backend — mirroring `NetworkServiceTests`'s use of
  `MockURLProtocol`.

## Out of scope (permanently not this layer's responsibility, this revision)

- **Client-streaming and bidirectional streaming.** Only server-streaming is a confirmed
  requirement. Source: SRS §1.2.
- **Replacing `Core/Networking`.** REST stays exactly as-is for every feature already built. This
  layer is additive; Repositories choose per feature/endpoint which transport to use.
- **Mutual TLS / client certificates.** Only standard server-authenticated TLS is required.
- **Automatic stream reconnection.** A dropped server-streaming call ends; resubscribing (if
  desired) is the calling feature's decision.
- **Retry policy**, for any RPC — same deliberate deferral as the REST layer
  (`Docs/Specs/Networking/requirements.md` § "Out of scope").
- **Any concrete gRPC service or `.proto` contract.** This spec defines only the reusable
  transport-client capability; no business service is defined here.

## Pending (not yet implemented — see `tasks.md`)

All of `Core/GRPC` is pending — nothing exists in code yet (confirmed by search: no file under
`InnerLamp/Core` matches `*grpc*`, and no reference in `InnerLamp.xcodeproj/project.pbxproj`).

> ⚠️ Not confirmed: no `.proto` service/method contract exists yet — blocks writing any concrete
> business RPC beyond the generic transport capability this spec defines. The first real consumer
> feature is not yet identified. Source: SRS Appendix A.

> ⚠️ Not confirmed: the concrete gRPC host(s)/port(s) for dev/staging/prod environments — blocks
> giving `APIConfig`'s gRPC extension real, non-placeholder values (a placeholder/local value must
> be used until the backend team confirms this). Source: SRS §3.1.4, Appendix A.

> ⚠️ Not confirmed: `grpc-swift v2`'s minimum supported OS/Swift version has not been checked
> against InnerLamp's current deployment target (`IPHONEOS_DEPLOYMENT_TARGET = 26.5`) — should be
> verified before or during implementation, when the SPM dependency is actually added. Source: SRS
> §2.4, Appendix A.

> ⚠️ Not confirmed: which feature will be the first real consumer of server-streaming — not tied to
> a specific feature yet. Does not block building the reusable `Core/GRPC` capability itself, but
> means there is no end-to-end example to validate the streaming API's ergonomics against until one
> exists. Source: SRS Appendix A.

> ⚠️ Not confirmed: whether long-lived server-streaming calls need explicit gRPC keepalive-ping
> tuning to survive NAT/proxy idle timeouts — not raised by the user; may need revisiting once a
> real streaming consumer exists. Source: SRS §3.3 NFR-002, Appendix A.

> ⚠️ Not confirmed: exact `grpc-swift v2` package version/tag to pin in `Package.swift` — left to
> implementation time; must be recorded in `design.md`/`changelog.md` once picked, not silently
> chosen. Source: SRS Appendix A.

## Open questions (resolved during SRS authoring)

- ~~Should this layer replace REST or coexist with it?~~ → Coexist — `Core/Networking` stays for
  all existing features; `Core/GRPC` is additive, chosen per feature/endpoint. Resolved 2026-09-28.
- ~~Does a `.proto` contract already exist?~~ → No — this spec covers only the reusable client-side
  transport core, no concrete service. Resolved 2026-09-28.
- ~~Which Swift gRPC library?~~ → `grpc-swift v2`. Resolved 2026-09-28.
- ~~How does gRPC auth relate to REST's bearer token?~~ → Same token, reused via
  `AuthTokenProviding`, attached as gRPC call-metadata. Resolved 2026-09-28.
- ~~TLS or mTLS?~~ → Standard server-authenticated TLS only; no client certificates. Resolved
  2026-09-28.
- ~~Is streaming needed now?~~ → Yes — server-streaming specifically; client-streaming and
  bidirectional are out of scope for this revision. Resolved 2026-09-28.
- ~~How are gRPC failures surfaced to Repositories?~~ → A new `GRPCError` type mirroring
  `NetworkError`'s role and shape. Resolved 2026-09-28.
- ~~Where does gRPC host/port config live?~~ → Extends the existing `APIConfig` (same
  `Environment` mechanism as REST). Resolved 2026-09-28.
- ~~Should gRPC calls be logged like REST calls?~~ → Yes — an interceptor mirrors `NetworkLogger`,
  routing through `LoggingService` and `PIIMasker`. Resolved 2026-09-28.
- ~~What is the default deadline, and is retry in scope?~~ → 30s default deadline (matches REST);
  retry policy explicitly deferred, same stance as `Docs/Specs/Networking`. Resolved 2026-09-28.
- ~~How are `.proto` files compiled to Swift?~~ → SPM build-tool plugin, generated at build time —
  nothing committed to git. Resolved 2026-09-28.
- ~~Is the channel shared or per-call?~~ → One shared, app-wide channel, built once (composition
  root). Resolved 2026-09-28.
- ~~How is a dropped streaming connection handled?~~ → No auto-reconnect — the stream ends and the
  calling feature decides whether to resubscribe. Resolved 2026-09-28.
- ~~How is this layer unit-tested without a live server?~~ → An in-process test server via
  `grpc-swift`'s own testing utilities, mirroring `MockURLProtocol`'s role for REST. Resolved
  2026-09-28.
