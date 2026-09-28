# Design — DeviceAttestation

Version: 1.2
Last updated: 2026-09-23
Status: in progress — Phases 1–3 implemented (Domain, Data, wiring); Phase 4 (API) blocked on backend contract

> See `changelog.md` in this folder for the version history of this spec.

## Overview

DeviceAttestation is a **background core service** (no UI, no Coordinator/ViewController/ViewModel)
that proves, via Apple **App Attest** (`DCAppAttestService`, iOS 14+), that the app instance making
sensitive requests is genuine and untampered: it attests a Secure Enclave key with Apple, then signs
sensitive requests with assertions the server can verify. This is the authoritative,
server-verifiable check against re-signed/fake apps.

It follows MVVM-C/Clean Architecture conventions but, being UI-less, lives in `Domain/` + `Data/`
with no `Presentation/Scenes/` folder. The public surface is a UseCase the caller invokes; **when**
to invoke it (launch, per-request, per-action) is the caller's decision and out of scope.

Jailbreak/root detection is **out of scope** (see `requirements.md`): App Attest certifies app
integrity, not device jailbreak status, and this feature deliberately does not add local heuristics.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILDeviceAttestationEntity.swift` | Pure business fields only: `keyId: String?`, `isAttested: Bool`, `isSupported: Bool`, `isBypassed: Bool`. No UI state, no framework types. |
| Domain / Repository | `Domain/Repositories/ILDeviceAttestationRepository.swift` | `nonisolated` protocol (Foundation only). Declares the device capability (`isAppAttestSupported`, `generateKey`, `attestKey`, `generateAssertion`) **and** the server ops (`fetchAttestationChallenge`, `submitAttestation`, `fetchAssertionChallenge`). Entity/`Data` in-out; throws `ILDeviceAttestationError`, never `NetworkError` or `DCError`. |
| Domain / UseCase | `Domain/UseCases/DeviceAttestation/ILDeviceAttestationUseCase.swift` | `protocol ILDeviceAttestationUseCase` + `final class ILDeviceAttestationUseCaseImpl` + `enum ILDeviceAttestationError`. Orchestrates the full flows, the bypass flag, and key persistence via `KeychainService`. |
| Data / DataSource | `Data/DataSources/Local/ILAppAttestDataSource.swift` | `nonisolated protocol ILAppAttestDataSource` + `nonisolated final class ILAppAttestDataSourceImpl` wrapping `DCAppAttestService.shared`. **The only file that imports `DeviceCheck`.** Maps `DCError` → `ILDeviceAttestationError`. |
| Data / Repository | `Data/Repositories/ILDeviceAttestationRepositoryImpl.swift` | Implements `ILDeviceAttestationRepository`; delegates the device capability to `ILAppAttestDataSource` and the server calls to `NetworkService` + endpoints. The only place DTOs exist above `NetworkService`. |
| Data / DTO | `Data/DTOs/ILDeviceAttestationDTO.swift` | `ILDeviceAttestationChallengeResponseDTO` (`Decodable`), `ILDeviceAttestationVerifyRequestDTO` (`Encodable`), `ILDeviceAttestationAssertionChallengeResponseDTO` (`Decodable`). ⚠️ shapes finalized in Phase 4. |
| Data / Mapper | `Data/DTOs/Mappers/ILDeviceAttestationMapper.swift` | `enum ILDeviceAttestationMapper` — static mapping between the (mostly `Data`) payloads and the DTOs. |
| Data / Endpoint | `Data/DataSources/Remote/AttestationChallengeEndpoint.swift`, `AttestationVerifyEndpoint.swift`, `AssertionChallengeEndpoint.swift` | Unprefixed `<Action>Endpoint` structs (`POST`/`GET`), `baseURL = APIConfig.serverBaseURL`. Paths provisional (see below). |

### Existing Core services (reused, not created)

| Service | Role in this feature |
|---|---|
| `Core/Storage/KeychainService.swift` | Persist the app-scoped App Attest `keyId` (one key, survives launch; wiped on reinstall/reset — re-attested automatically). |
| `Core/Storage/UserDefaultsService.swift` | The bypass flag (`deviceAttestation.bypass`, default `false`) for Simulator/dev runs. |

## Invocation model (deferred)

There is no navigation flow and no scene. The caller owns the "when" decision and calls the
UseCase directly, e.g.:

```
<caller decides the trigger>
  └─ attestDevice()              → ILDeviceAttestationEntity  (throws on failure — fail-closed)
  └─ generateAssertion(clientData:) → Data assertion          (throws on failure)
```

## Step-by-step Flow — App Attest

Both flows involve 2+ sequential calls (challenge → attest → verify; challenge → assert), so the
sequence is spelled out per step. Steps marked "(server)" have a provisional contract — the data
shape is Apple-standard; the endpoint path/envelope follows the confirmed convention (see below).

### Attestation flow (`attestDevice()`)

```
Step 1 — Support + bypass gate (no network)
- Trigger: caller invokes attestDevice()
- Pre-condition: none
- Logic:
    - bypass flag ON → return ILDeviceAttestationEntity(isAttested: true, isBypassed: true,
      keyId: nil) WITHOUT contacting Apple or the server.
    - isAppAttestSupported == false → throw .unsupported (fail-closed).
    - else continue.
    - Success → Step 2
    - Failure (unsupported, no bypass) → throw .unsupported

Step 2 — Ensure key exists (Apple, on-device)
- Trigger: Step 1 success
- Pre-condition: App Attest supported
- API: DCAppAttestService.generateKey() → keyId
    - If a keyId is already persisted in the Keychain, reuse it (skip generation).
    - Success → persist keyId in Keychain, go to Step 3
    - Failure (DCError) → throw mapped ILDeviceAttestationError (e.g. .keyGenerationFailed)

Step 3 — Fetch attestation challenge (server)
- Trigger: Step 2 success
- Pre-condition: a keyId exists (may or may not be attested yet)
- API: GET /v1/attestation/challenge   (provisional path)
    - Success → one-time challenge Data, go to Step 4
    - Failure (network/timeout/server) → throw mapped ILDeviceAttestationError

Step 4 — Attest the key (Apple, on-device)
- Trigger: Step 3 success
- Pre-condition: challenge received
- API: DCAppAttestService.attestKey(keyId, clientDataHash: SHA256(challenge)) → attestation object
    - Success → attestation Data, go to Step 5
    - Failure (DCError.invalidKey = key already attested or stale) → if stale, discard keyId,
      regenerate, and loop back to Step 3; otherwise throw mapped error
    - Failure (DCError.serverUnavailable) → throw retryable error (.server)

Step 5 — Submit attestation for verification (server)
- Trigger: Step 4 success
- Pre-condition: attestation object produced
- API: POST /v1/attestation/verify (keyId, attestation, challenge)   (provisional path)
    - Success → server verified the key with Apple; mark key as attested, return
      ILDeviceAttestationEntity(keyId, isAttested: true)
    - Failure (server rejects attestation) → throw .attestationRejected; discard keyId so the next
      call re-attests
    - Failure (network/timeout/server) → throw mapped ILDeviceAttestationError
```

### Assertion flow (`generateAssertion(clientData:)`)

```
Step 1 — Bypass gate (no network)
- Trigger: caller invokes generateAssertion(clientData:)
- Pre-condition: none
- Logic: bypass flag ON → throw .bypassed (no real key exists in this mode)
    - Failure (bypassed) → throw .bypassed

Step 2 — Load keyId (Keychain)
- Trigger: Step 1 passes
- Pre-condition: attestDevice() previously succeeded
- Logic: read keyId from Keychain
    - Success → go to Step 3
    - Failure (no key) → throw .assertionFailed (caller should attest first)

Step 3 — Fetch assertion challenge (server)
- Trigger: Step 2 success
- API: GET /v1/assertion/challenge   (provisional path)
    - Success → one-time challenge Data, go to Step 4
    - Failure (network/timeout/server) → throw mapped ILDeviceAttestationError

Step 4 — Generate assertion (Apple, on-device)
- Trigger: Step 3 success
- Pre-condition: challenge received; clientData prepared by caller (challenge + request context)
- API: DCAppAttestService.generateAssertion(keyId, clientDataHash: SHA256(clientData)) → assertion
    - Success → assertion Data (returned to the caller to attach to the request; the server
      verifies it against Apple)
    - Failure (DCError) → throw mapped ILDeviceAttestationError
```

## Data shapes (Apple-standard) + confirmed convention

The client↔server payloads are defined by Apple's App Attest protocol, so the *values* are stable
even though the backend's exact paths/error codes are still provisional:

| Item | Type | Source / destination |
|---|---|---|
| `keyId` | `String` (base64) | generated on device, sent to server at attest time, reused on every assertion |
| `challenge` | `Data` | server → client, one-time, random per call |
| `attestation object` | `Data` (CBOR) | Apple → client (Step 4), client → server (Step 5) |
| `assertion` | `Data` (CBOR) | Apple → client, client → server as a header on the protected request |
| `clientData` | `Data` | caller builds (challenge + method + path + body SHA-256); hashed before signing |

Confirmed convention (2026-09-23): the three endpoints follow the shared `ApiResponse` envelope
(`{"success": true, "data": …}` / `{"success": false, "error": {code, message, type}, "details"?}`)
handled by `NetworkService`. Provisional paths: `GET /v1/attestation/challenge`,
`POST /v1/attestation/verify`, `GET /v1/assertion/challenge` — the user may rename these later.
Concrete error codes are TBD by the backend team (⚠️ in `requirements.md`).

## Server-side responsibilities (out of scope, listed for the backend team)

This feature only builds the client. The server must still: validate the attestation certificate
chain, the App ID hash, the environment `aaguid`, the credential ID, and the nonce
`SHA256(authData ‖ SHA256(challenge))`; store the verified public key + receipt; and on every
assertion validate the signature, RP ID, the monotonically-increasing assertion counter, the
one-time challenge, and the request binding (replay protection). These are documented here so the
backend contract in Phase 4 covers them, but no client code implements them.

## Bypass flag, key persistence, and environment

- **Bypass flag** — `UserDefaultsService` key `deviceAttestation.bypass` (default `false`). Used
  for Simulator/dev: on Simulator `DCAppAttestService.isSupported == false`, so the default is
  fail-closed; setting the flag `true` makes `attestDevice()` short-circuit to success and
  `generateAssertion(...)` throw `.bypassed` so local runs proceed without a real key.
- **Key persistence** — the `keyId` is stored in the Keychain, app-scoped (no account identifier,
  per the resolved key-scope decision). App *updates* keep the key; *reinstall/factory reset* wipes
  both the Secure Enclave key and the Keychain entry, so the next `attestDevice()` re-attests.
- **Environment entitlement** — the App Attest environment entitlement
  (`com.apple.developer.devicecheck.appattest-environment`, `development` vs `production`) must be
  set and kept consistent with the server environment (sandbox keys do not verify in production and
  vice versa). See `tasks.md` Phase 3.

## Error mapping (`ILDeviceAttestationError`)

Declared in `ILDeviceAttestationUseCase.swift` (per convention). Exhaustive over both `DCError`
(mapped in `ILAppAttestDataSourceImpl`) and `NetworkError` (mapped in
`ILDeviceAttestationRepositoryImpl`):

| Case | Source |
|---|---|
| `.unsupported` | App Attest not supported and bypass off |
| `.bypassed` | assertion requested while bypass is on (no real key) |
| `.keyGenerationFailed` | `DCError` during `generateKey` |
| `.attestationRejected` | server rejected the attestation |
| `.challengeFailed` | challenge fetch failed |
| `.assertionFailed` | assertion generation failed / no key |
| `.server` | shared server error |
| `.networkUnavailable` | shared no-internet |
| `.timedOut` | shared timeout |

`DCError.serverUnavailable` maps to `.server` (retryable) rather than a terminal failure; `DCError`
`.invalidKey` during attestation triggers discard-and-regenerate (Step 4), not a thrown terminal
error.

## Deliberately stubbed for now

The three server endpoints (`AttestationChallengeEndpoint`, `AttestationVerifyEndpoint`,
`AssertionChallengeEndpoint`) have a confirmed envelope/mechanism but provisional paths, so their
`ILDeviceAttestationRepositoryImpl` methods are **one-line `// TODO: real API` stubs** until
Phase 4 — the project rule "never fake a Repository call" applies. The Apple device capability
(Steps 2/4, assertion Step 4) is a real implementation; only the server round-trips are stubbed.
