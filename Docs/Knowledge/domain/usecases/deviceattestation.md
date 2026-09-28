---
type: UseCase
title: Device Attestation
description: UI-less core service that proves via Apple App Attest that the app instance making a sensitive request is genuine and untampered — attestDevice() attests a Secure Enclave key with Apple; generateAssertion(clientData:) signs sensitive requests.
resource: InnerLamp/Domain/UseCases/DeviceAttestation/ILDeviceAttestationUseCase.swift
tags: [domain, usecase, security, app-attest]
status: draft
generated: { by: claude-code, at: 2026-09-23T22:52:08+07:00 }
sources:
  - path: Docs/Specs/DeviceAttestation/requirements.md
    kind: spec
  - path: Docs/Specs/DeviceAttestation/design.md
    kind: spec
  - path: InnerLamp/Domain/Entities/ILDeviceAttestationEntity.swift
    kind: code
  - path: InnerLamp/Domain/Repositories/ILDeviceAttestationRepository.swift
    kind: code
  - path: InnerLamp/Domain/UseCases/DeviceAttestation/ILDeviceAttestationUseCase.swift
    kind: code
  - path: InnerLamp/Data/DataSources/Local/ILAppAttestDataSource.swift
    kind: code
  - path: InnerLamp/Data/Repositories/ILDeviceAttestationRepositoryImpl.swift
    kind: code
---

# Summary

DeviceAttestation is a **UI-less background core service** (no Coordinator,
ViewController, or ViewModel) that proves, via Apple **App Attest**
(`DCAppAttestService`, iOS 14+), that the app instance making a sensitive
request is genuine and untampered: it attests a Secure Enclave key with Apple,
then signs sensitive requests with assertions the server can verify. Its public
surface is the `ILDeviceAttestationUseCase` protocol with two actions:

- `attestDevice()` — the full attestation flow (support/bypass gate → ensure key
  → challenge → attest → server verify), returning an `ILDeviceAttestationEntity`.
- `generateAssertion(clientData:)` — loads the persisted key, fetches a fresh
  challenge, and returns a signed assertion the caller attaches to a protected
  request.

The caller owns *when* to invoke it (launch, per-request, per-action) — this
service is only the callable core. Jailbreak/root detection is deliberately out
of scope: App Attest certifies app integrity, not jailbreak status.

**Current limitation**: the Apple on-device steps are real, but the three server
round-trips are `// TODO` stubs until the backend contract lands (Phase 4) — see
[Stub status](#stub-status).

# Architecture

UI-less, so this service lives in `Domain/` + `Data/` with no
`Presentation/Scenes/` folder. It follows Clean Architecture layering
(Entity → Repository protocol → UseCase → DataSource / Repository impl) and is
wired in `DIContainer`.

| Layer | Type | File |
|---|---|---|
| Domain / Entity | Domain Entity | `Domain/Entities/ILDeviceAttestationEntity.swift` — pure fields `keyId`, `isAttested`, `isSupported`, `isBypassed`; Foundation only |
| Domain / Repository | Repository protocol | `Domain/Repositories/ILDeviceAttestationRepository.swift` — `nonisolated`; device capability (`isAppAttestSupported`, `generateKey`, `attestKey`, `generateAssertion`) + server ops (`fetchAttestationChallenge`, `submitAttestation`, `fetchAssertionChallenge`); throws `ILDeviceAttestationError`, never `NetworkError`/`DCError` |
| Domain / UseCase | UseCase | `Domain/UseCases/DeviceAttestation/ILDeviceAttestationUseCase.swift` — `protocol ILDeviceAttestationUseCase` + `final class ILDeviceAttestationUseCaseImpl` + `enum ILDeviceAttestationError` |
| Data / DataSource | DataSource | `Data/DataSources/Local/ILAppAttestDataSource.swift` — wraps `DCAppAttestService.shared`; **the only file that imports `DeviceCheck`**; maps `DCError` → `ILDeviceAttestationError` |
| Data / Repository | Repository impl | `Data/Repositories/ILDeviceAttestationRepositoryImpl.swift` — delegates device capability to the DataSource (real); the three server ops are one-line `// TODO` stubs |
| App / DI | Composition root | `App/DIContainer.swift` — `appAttestDataSource` lazy var, `makeDeviceAttestationRepository()`, `makeDeviceAttestationUseCase()` |
| Tests | Unit tests | `InnerLampTests/ILDeviceAttestationUseCaseTests.swift` — drives `ILDeviceAttestationUseCaseImpl` over a `MockILDeviceAttestationRepository` |

Reused Core services: `KeychainService` (persists the app-scoped `keyId`) and
`UserDefaultsService` (the `deviceAttestation.bypass` flag). The App Attest
environment entitlement lives in `InnerLamp/InnerLamp.entitlements`
(`com.apple.developer.devicecheck.appattest-environment = development`).

`ILDeviceAttestationError` is declared in the UseCase file (per project
convention) and is deliberately **not** `LocalizedError` — it carries no
user-facing text, because the caller that decides to block an action owns the
presentation and maps these cases to whatever message/UI it wants.

# Interface

| Member | Signature | Behaviour |
|---|---|---|
| `attestDevice` | `func attestDevice() async throws -> ILDeviceAttestationEntity` | Runs the full attestation flow and returns the resulting state; throws `unsupported` (unsupported + bypass off), `attestationRejected` (server rejected), or `keyGenerationFailed` / `challengeFailed` / `server` / `networkUnavailable` / `timedOut` for a failed step |
| `generateAssertion` | `func generateAssertion(clientData: Data) async throws -> Data` | Loads the persisted key, fetches a challenge, and returns a signed assertion; throws `bypassed` (bypass on — no real key), `assertionFailed` (no key / stale), or a step failure |

`ILDeviceAttestationUseCaseImpl` is the real implementation, registered in
`DIContainer.makeDeviceAttestationUseCase()` (which also injects the repository,
`KeychainService`, and `UserDefaultsService`). SHA-256 hashing does not happen in
the UseCase — it lives in `ILAppAttestDataSource`, right before each
`DCAppAttestService` call, keeping the Domain layer Foundation-only.

# Business rules

- **Fail-closed everywhere**: any failure throws rather than returning a result
  the caller could mistakenly trust. On an unsupported device with the bypass
  flag off, `attestDevice()` throws `unsupported` **without contacting the
  server**.
- **Bypass flag short-circuit** (`UserDefaultsService` key
  `deviceAttestation.bypass`, default `false`): when on, `attestDevice()`
  returns a synthetic `ILDeviceAttestationEntity(isAttested: true, isBypassed:
  true)` without contacting Apple or the server; `generateAssertion(...)` throws
  `bypassed` (there is no real key in this mode).
- **Key reuse + persistence**: the app-scoped `keyId` is persisted in the
  Keychain under `device_attestation_key_id` (one key per install); a supported
  device reuses it instead of regenerating. App updates keep the key;
  reinstall/factory reset wipes it.
- **Stale-key auto-recovery**: when `attestKey` surfaces `DCError.invalidKey`
  (the persisted key no longer matches a live Secure Enclave key), the UseCase
  discards the key, regenerates, and re-attests — **at most once**, then throws
  `assertionFailed`.
- **Rejected attestation discards the key**: on `attestationRejected`, the key
  is discarded so the next call re-attests fresh.
- **Retryable vs terminal**: `DCError.serverUnavailable` maps to `server`
  (retryable), not a terminal failure; `DCError.invalidKey` is an internal-only
  signal (never surfaced to the caller); `DCError.featureUnsupported` maps to
  `unsupported`.

# Dependencies

| Dependency | Injected via | Notes |
|---|---|---|
| `ILDeviceAttestationRepository` | `init` | Real impl delegates device capability to `ILAppAttestDataSource`; server ops will round-trip through `NetworkService` (Phase 4) |
| `KeychainService` | `init` | Persists / loads / deletes the app-scoped `keyId` (`device_attestation_key_id`) |
| `UserDefaultsService` | `init` | Reads the `deviceAttestation.bypass` flag |

# Stub status

The UseCase's own orchestration is real and fully unit-tested, but the three
server ops in `ILDeviceAttestationRepositoryImpl` are one-line `// TODO: real
API` stubs that **fail closed** (throw rather than fabricate data):

- `fetchAttestationChallenge()` → throws `ILDeviceAttestationError.challengeFailed`
  (`GET /v1/attestation/challenge`, provisional path)
- `submitAttestation(keyId:attestation:challenge:)` → throws
  `ILDeviceAttestationError.server` (`POST /v1/attestation/verify`, provisional path)
- `fetchAssertionChallenge()` → throws `ILDeviceAttestationError.challengeFailed`
  (`GET /v1/assertion/challenge`, provisional path)

Consequence: `attestDevice()` / `generateAssertion(...)` complete their on-device
steps but always throw at the first server call. `NetworkService` is
deliberately **not** injected into the repository yet — no DTO/Mapper/Endpoint
exists, per the project's "never fake a Repository call" rule. The Apple device
capability (`generateKey`, `attestKey`, `generateAssertion`) is real.

# Pending work

- Phase 4 (API integration) is blocked on the backend contract: the envelope /
  mechanism are confirmed, but the exact endpoint paths and error codes are not
  yet fixed in `Docs/Specs/API/openapi.yaml`. Once confirmed: create the DTOs +
  Mapper, the three real `Endpoint` conformances, replace the stubs with
  `NetworkService` calls, map `NetworkError` → `ILDeviceAttestationError`, add
  `InnerLampTests/ILDeviceAttestationRepositoryTests.swift`, and manually test
  against a real/staging backend.
- `ILAppAttestDataSource` is not unit-testable (`DCAppAttestService` is a
  non-injectable Apple singleton and App Attest only runs on real hardware), so
  its `DCError` mapping is covered by manual / integration testing.
- Whether the Keychain `keyId` survives app updates and is wiped on reinstall is
  a manual check (`Docs/Specs/DeviceAttestation/tasks.md` Phase 3, still open).
- The caller's decision of *when* to invoke the service (launch, per-request,
  per-action) is out of scope and tracked elsewhere.
- Promote to `stable` only after the server round-trips are real and the full
  attestation + assertion flows are exercised end-to-end against a real/staging
  backend.

# Related concepts

- `ILDeviceAttestationEntity`
  (`InnerLamp/Domain/Entities/ILDeviceAttestationEntity.swift`) — the result
  struct this UseCase returns. It is a thin, single-consumer value and is
  documented here rather than as its own `domain/entities/` concept; a separate
  entity concept can be added later if it becomes shared.
- App Attest endpoint concepts (`Docs/Knowledge/api/`) — **not yet written**;
  the request/response shapes are still provisional and documented in
  `Docs/Specs/DeviceAttestation/design.md`.
- [Device Attestation spec](../../../Specs/DeviceAttestation/requirements.md) —
  the work-order spec this concept was reconciled against
  (`Docs/Specs/DeviceAttestation/`, v1.2).
- No Feature concepts call this service yet — it is a background core service
  awaiting its first caller (the invocation decision is deferred, tracked in the
  spec's "Deferred" section).
