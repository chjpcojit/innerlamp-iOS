# Software Requirements Specification — DeviceAttestation

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | DeviceAttestation |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-09-27 |
| Status | retroactive — reconstructed from `requirements.md` / `design.md` / `tasks.md` |
| Owner / author | ba-writer (Business Analyst) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

This document is the Software Requirements Specification for the **DeviceAttestation** core service of
InnerLamp. It defines — for the security team, the PM, and engineering — *what* the service must do, at
business level, in IEEE 29148-2018 form. It is reconstructed retroactively from the already-implemented
service and its engineering spec (`requirements.md` / `design.md` / `tasks.md`).

### 1.2 Scope

**In scope:**

- A background, UI-less core service that proves — via Apple **App Attest**
  (`DCAppAttestService`, iOS 14+) — that the app instance making sensitive requests is a genuine,
  untampered app on a genuine Apple device.
- Two callable operations: `attestDevice()` (full attestation) and
  `generateAssertion(clientData:)` (per-request signing).
- Persistent, app-scoped Secure Enclave key handling, including automatic re-attestation when a stored
  key goes stale (e.g. after reinstall or factory reset).
- A development bypass flag and a fail-closed error model (`ILDeviceAttestationError`).

**Out of scope:**

- **Jailbreak/root detection** — App Attest certifies app integrity, not device jailbreak status, and
  Apple exposes no jailbreak-status API. Deliberately deferred.
- The decision of **when** to invoke the service (app launch, per request, per action) — owned by the
  caller.
- Server-side verification logic (certificate-chain, nonce, assertion counter, replay protection) — the
  client only fetches/sends the Apple-standard data.
- Any user-facing "device blocked" UI.
- `DCDevice` (DeviceCheck) tokens — App Attest is the chosen mechanism.

### 1.3 Product overview

InnerLamp is a Buddhist companion app (UIKit, Swift, Clean Architecture + MVVM-C). DeviceAttestation is a
**new core security service** that sits in the `Domain/` + `Data/` layers (no `Presentation/Scenes/`
folder) and gives the operator cryptographic confidence that sensitive requests come from a genuine,
untampered app instance — the primary API-abuse vector — rather than a re-signed, modified, or fake app.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| App Attest | Apple's service (`DCAppAttestService`) that cryptographically proves, via the Secure Enclave, that a specific app instance is genuine and runs on a genuine Apple device. |
| Attestation | The one-time process of generating a key, obtaining a one-time challenge, attesting the key with Apple, and submitting the result to the server for verification. |
| Assertion | A signed statement over the SHA-256 hash of caller-provided client data, produced from the attested key, attached by callers to sensitive requests. |
| `keyId` | A base64 identifier for the Secure Enclave key, persisted in the Keychain, app-scoped. |
| Fail-closed | On any failure the operation throws; it never silently treats a key as attested or returns an unverifiable assertion. |
| Bypass flag | A `UserDefaults` flag (`deviceAttestation.bypass`, default `false`) that short-circuits the service for Simulator/dev runs. |
| DeviceCheck (`DCDevice`) | The alternative Apple mechanism that tracks a *device* identity — explicitly **not** used here. |

### 1.5 References

- `Docs/Specs/DeviceAttestation/requirements.md`, `design.md`, `tasks.md`, `changelog.md` — the
  engineering spec this SRS reconstructs.
- `Docs/Specs/API/openapi.yaml` — the shared `ApiResponse` envelope contract (attestation endpoints are
  not yet defined there).
- `InnerLamp/Domain/UseCases/DeviceAttestation/` — implemented service (Phases 1–3 shipped).

### 1.6 Document organization

§2 describes the service at a product level. §3 gives the specific functional (`FR-*`) and
non-functional (`NFR-*`) requirements. §4 defines verification and the traceability matrix. §5 lists
open questions.

---

## 2. Overall description

### 2.1 Product perspective

This is a **new core service** within InnerLamp. It is infrastructure, not a screen: there is no
Coordinator, ViewController, ViewModel, or navigation flow. It touches one external system — a **backend
API** (not yet built) that issues one-time challenges and verifies attestations/assertions; the client
proposes the contract. It depends on Apple's `DeviceCheck` framework and the existing `KeychainService`
/ `UserDefaultsService` / `NetworkService`.

### 2.2 Product functions

- Prove app-instance genuineness via App Attest (`FR-001`, `FR-002`).
- Handle support detection, key reuse, and stale-key re-attestation (`FR-003`, `FR-004`).
- Produce per-request assertions for sensitive calls (`FR-005`).
- Provide a development bypass and a fail-closed error model (`FR-006`, `FR-007`).

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| InnerLamp operator (server / security team) | Relies on the service so the server can reject requests from tampered/fake apps. | Consumes attestations/assertions; owns the server-side verification logic (out of scope here). |
| Feature developer (caller) | Invokes `attestDevice()` / `generateAssertion(...)` from other features. | Decides *when* to invoke; is expected to skip attaching an assertion in bypass mode. |
| End user | Unaware of the service. | No interaction; there is no UI. |

### 2.4 Operating environment

- Platform: iOS 14+ (App Attest minimum).
- Devices: iPhone (primary); App Attest runs on real hardware, not the Simulator (where
  `isAppAttestSupported == false` and the default is fail-closed).
- Network: required only for the challenge/verify round-trips; the support/key steps are on-device.

### 2.5 Design and implementation constraints

- Swift + Clean Architecture, per `AGENTS.md`; the service lives in `Domain/` + `Data/` with **no**
  `Presentation/Scenes/` folder.
- `Domain` is `Foundation`-only (no UIKit/DeviceCheck import); `DeviceCheck` is imported **only** in
  `Data/DataSources/Local/ILAppAttestDataSource.swift`.
- Manual DI via `DIContainer`; server ops route through `NetworkService`.
- Key persistence via `KeychainService`; the bypass flag via `UserDefaultsService`.
- The App Attest environment entitlement must stay consistent with the server environment
  (development vs production).

### 2.6 User documentation

**N/A** — this is an internal security service with no user-facing surface.

### 2.7 Assumptions and dependencies

- **Assumptions:**
  - A backend exists (or will) that issues one-time challenges and verifies attestations/assertions
    against Apple.
  - One App Attest key per app install (per-app scope, not per-device and not per-account).
  - Browsing/sensitive actions are the consumers; the service itself is trigger-agnostic.
- **Dependencies:**
  - Apple `DeviceCheck` (`DCAppAttestService`) — iOS 14+.
  - `Core/Storage/KeychainService` (key persistence) and `Core/Storage/UserDefaultsService` (bypass).
  - `Core/Networking` (`NetworkService`, shared `ApiResponse` envelope).
  - The backend attestation endpoints — provisional paths, contract not yet fixed (§3.1.3).

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

**N/A** — the service is UI-less; it owns no screen and no Coordinator/ViewController/ViewModel.

#### 3.1.2 Hardware interfaces

**N/A** — this is an iOS application service with no custom hardware interface (the Secure Enclave is a
platform facility, not an app-defined interface).

#### 3.1.3 Software interfaces

The backend REST API is **not yet built**; the client proposes the contract (mock-first). The shared
`ApiResponse` envelope and the Apple-standard payloads are confirmed; the endpoint paths are provisional:

- `GET /v1/attestation/challenge` — one-time attestation challenge.
- `POST /v1/attestation/verify` — submit `keyId` + attestation + challenge for server verification.
- `GET /v1/assertion/challenge` — one-time assertion challenge.

The Apple-standard data shapes (`keyId`, `challenge`, CBOR attestation/assertion, `clientData`) are
stable even though the paths are not.

> ⚠️ Not confirmed: the exact endpoint paths and the concrete error-code vocabulary for the server's
> reject/verify responses (e.g. `ATTESTATION_INVALID`, `KEY_ALREADY_ATTESTED`, `CHALLENGE_EXPIRED`) —
> blocks the DTO, Mapper, Endpoint, and Repository implementation (Phase 4).

#### 3.1.4 Communication interfaces

- HTTPS + JSON through the shared `ApiResponse` envelope (`{"success": true, "data": …}` /
  `{"success": false, "error": {code, message, type}}`), handled by `NetworkService`.
- Assertions are attached by the *caller* to protected requests as a header; this service only produces
  them.

### 3.2 Functional requirements

#### Attestation (`attestDevice()`)

**FR-001 — Determine support and gate**
- **Priority:** Must
- **Description:** WHEN `attestDevice()` is invoked, THE SYSTEM SHALL determine whether App Attest is
  supported; on an unsupported device with the bypass flag OFF it SHALL throw
  `ILDeviceAttestationError.unsupported` and SHALL NOT contact the server (fail-closed).
- **Verification method:** Unit test (mock repository) + manual QA on Simulator.
- **Source:** EARS acceptance criterion (support/bypass gate).

**FR-002 — Reuse or create the key and attest**
- **Priority:** Must
- **Description:** WHEN App Attest is supported, THE SYSTEM SHALL reuse the persisted attested key if
  one exists, otherwise generate + persist a new key and perform the full attestation
  (fetch challenge → attest → submit for verification).
- **Verification method:** Unit test (mock repository).
- **Source:** EARS acceptance criterion (key reuse + full attestation).

**FR-003 — Return the attestation result**
- **Priority:** Must
- **Description:** WHEN `attestDevice()` completes, THE SYSTEM SHALL return an
  `ILDeviceAttestationEntity` reflecting `keyId`, `isAttested`, and `isSupported`.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (entity shape).

**FR-004 — Re-attest on a stale key**
- **Priority:** Must
- **Description:** WHEN the persisted `keyId` no longer matches a live Secure Enclave key
  (`DCError.invalidKey`, e.g. after reinstall/factory reset), THE SYSTEM SHALL discard the stale key,
  generate a new key, and re-attest within the same `attestDevice()` call.
- **Verification method:** Unit test (stale-key re-attest).
- **Source:** EARS acceptance criterion (auto re-attest).

#### Assertion (`generateAssertion(clientData:)`)

**FR-005 — Generate a signed assertion**
- **Priority:** Must
- **Description:** WHEN `generateAssertion(clientData:)` is invoked, THE SYSTEM SHALL load the persisted
  `keyId`, fetch a fresh one-time challenge, and return a signed assertion over the SHA-256 hash of the
  client data; on any failure it SHALL throw rather than return an unverifiable assertion.
- **Verification method:** Unit test (mock repository).
- **Source:** EARS acceptance criterion (assertion flow).

#### Cross-cutting

**FR-006 — Bypass short-circuit**
- **Priority:** Must
- **Description:** WHEN the bypass flag is enabled, THE SYSTEM SHALL short-circuit `attestDevice()` to a
  synthetic success (`isAttested = true`, `isBypassed = true`) without contacting Apple or the server,
  and `generateAssertion(...)` SHALL throw `ILDeviceAttestationError.bypassed`.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (bypass mode).

**FR-007 — Fail-closed error model**
- **Priority:** Must
- **Description:** WHEN any step of attestation or assertion fails (key generation, challenge fetch,
  Apple's attestation call, or server verification), THE SYSTEM SHALL throw the corresponding
  `ILDeviceAttestationError` and SHALL NOT mark the key as attested. WHEN Apple reports
  `DCError.serverUnavailable`, THE SYSTEM SHALL surface it as a retryable error rather than treating the
  key as attested.
- **Verification method:** Unit test (error mapping) + manual QA.
- **Source:** EARS acceptance criteria (fail-closed; serverUnavailable retryable).

### 3.3 Performance requirements

- **NFR-001 — On-device steps:** support detection and key generation/attestation are on-device
  Secure Enclave operations; the only network-bound steps are the challenge/verify round-trips, which
  must not block other flows (the service is `async`).
- **NFR-002 — No silent retries:** the service performs no retry loop of its own; a transport failure
  maps to an `ILDeviceAttestationError` and is returned to the caller (retry policy is out of scope).

### 3.4 Logical database requirements

- **Client-side:** the only persisted data is the app-scoped `keyId` in the Keychain. It survives app
  *updates* and is wiped on *reinstall/factory reset*, after which the next `attestDevice()` re-attests.
- **Server-side (authoritative):** the server stores the verified public key + attestation receipt for
  the app instance — backend responsibility, out of scope here.

### 3.5 Design constraints

- Follow Clean Architecture: `ILDeviceAttestationEntity` (pure business fields, Domain) vs
  `ILDeviceAttestationRepository` (protocol, Domain) vs `ILAppAttestDataSource` +
  `ILDeviceAttestationRepositoryImpl` + DTO/Mapper (Data). Never mix concerns.
- `DeviceCheck` is imported in exactly one file; `DCError` is mapped to `ILDeviceAttestationError` at
  the DataSource boundary, and `NetworkError` at the Repository boundary.
- No force unwrapping; `async throws` throughout.

### 3.6 Software system attributes

- **Reliability:** fail-closed everywhere — no path silently marks a key attested or returns an
  unverifiable assertion.
- **Availability:** the on-device steps work offline; only the challenge/verify round-trips require the
  backend, and their failure surfaces as a typed error.
- **Security:** cryptographic proof via the Secure Enclave; no PII is collected or stored; the `keyId`
  is a non-PII key identifier held in the Keychain; the bypass flag is dev-only and default-off.
- **Maintainability:** each functional requirement maps to a unit-testable UseCase seam; `Domain` stays
  `Foundation`-only.
- **Portability:** the Domain layer is device-agnostic; the `DeviceCheck` dependency is isolated in one
  Data-layer file.

---

## 4. Verification & traceability

### 4.1 Verification approach

- **Unit tests** (`XCTest`) for the UseCase flows via a mock `ILDeviceAttestationRepository`: success,
  `.unsupported`, `.bypassed`, fail-closed, and stale-key re-attest.
- **Manual / integration QA** for the real `DCAppAttestService` behavior (App Attest runs on real
  hardware, not the Simulator) and the environment-entitlement consistency.
- **Code review** for the `DCError` → `ILDeviceAttestationError` mapping in the DataSource.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Support/bypass gate | → spec-writer | TBD |
| FR-002 | Key reuse + attestation | → spec-writer | TBD |
| FR-003 | Entity shape | → spec-writer | TBD |
| FR-004 | Auto re-attest | → spec-writer | TBD |
| FR-005 | Assertion flow | → spec-writer | TBD |
| FR-006 | Bypass mode | → spec-writer | TBD |
| FR-007 | Fail-closed + retryable server | → spec-writer | TBD |
| NFR-001 | Async on-device steps | → spec-writer | TBD |
| NFR-002 | No silent retries | → spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: the exact endpoint paths (`GET /v1/attestation/challenge`,
> `POST /v1/attestation/verify`, `GET /v1/assertion/challenge` proposed) and the concrete error-code
> vocabulary for the server's reject/verify responses — blocks the DTO, Mapper, Endpoint, and Repository
> (Phase 4).

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Mechanism | App Attest (`DCAppAttestService`), not `DCDevice`/DeviceCheck | 2026-09-23 |
| Key scope | Per-app (one key per app install) | 2026-09-23 |
| UI vs service | Background core service, no UI | 2026-09-23 |
| Fail policy | Fail-closed | 2026-09-23 |
| Unsupported devices | Unsupported = failed by default; `UserDefaults` bypass flag for dev/Simulator | 2026-09-23 |
| Re-attest on stale key | Auto-detect and re-attest | 2026-09-23 |
| Jailbreak/root detection | Out of scope (App Attest does not provide it) | 2026-09-23 |
| Envelope convention | Shared `ApiResponse` envelope, Apple-standard challenge/verify/assert data | 2026-09-23 |
