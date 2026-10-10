# Software Requirements Specification — Networking

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | Networking |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-09-27 |
| Status | retroactive — reconstructed from `requirements.md` / `design.md` / `tasks.md` |
| Owner / author | ba-writer (Business Analyst) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

This document is the Software Requirements Specification for the **Networking** core layer of
InnerLamp. It defines — for the PM and engineering — *what* the layer must do, at business level, in
IEEE 29148-2018 form. It is reconstructed retroactively from the implemented `Core/Networking` layer
and its engineering spec.

### 1.2 Scope

**In scope:**

- The single transport boundary every business API call passes through (`Endpoint`, `NetworkService`).
- Central auth-header injection, response-envelope decoding, explicit session configuration, and
  per-request logging.
- A discriminated error model (`NetworkError`, including the envelope's `error.code` + `details`).

**Out of scope:**

- **Retry policy** — explicitly deferred by the user.
- **Token refresh on 401** — undecided who owns it.
- **Multipart and `application/x-www-form-urlencoded` encoding** — JSON only.
- **Reachability pre-check** — `URLError` classification is the single source of truth.

### 1.3 Product overview

InnerLamp is a Buddhist companion app (UIKit, Swift, Clean Architecture + MVVM-C). `Core/Networking` is
the **infrastructure** layer (not a feature-scene) that every feature `Repository` calls; it handles
auth headers, envelope decoding, timeouts, and logging so feature developers cannot mis-decode a
failure.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Envelope | The backend's standard `ApiResponse` wrapper (`{"success": …, "data": …, "error": …, "details": …}`). |
| `error.code` | The machine-readable discriminator in the envelope's `error` object, used to distinguish failures that share a status code. |
| `details` | The envelope's free-form map (`[String: AnyCodable]`) carrying failure extras (e.g. `locked_until`, `retry_after_seconds`). |
| `requiresAuth` | An `Endpoint` flag (default `true`) declaring whether a request may carry the stored bearer token. |
| Bare decoding | Decoding a response without envelope unwrapping (metadata endpoints such as localization). |

### 1.5 References

- `Docs/Specs/Networking/requirements.md`, `design.md`, `tasks.md`, `changelog.md`.
- `Docs/Specs/API/openapi.yaml` — the backend contract the envelope models.
- `InnerLamp/Core/Networking/` — the implemented layer.

### 1.6 Document organization

§2 describes the layer at a product level. §3 gives the functional (`FR-*`) and non-functional
(`NFR-*`) requirements. §4 defines verification and the traceability matrix. §5 lists open questions.

---

## 2. Overall description

### 2.1 Product perspective

This is **core infrastructure** within InnerLamp, not a feature-scene: there is no screen, Coordinator,
ViewModel, or `DIContainer` feature section. It touches one external system — the **backend API** —
and is consumed by every feature `Repository` (Data layer). It is the layer that keeps a transport
change (e.g. a future gRPC migration) scoped to `Core/Networking` rather than app-wide.

### 2.2 Product functions

- Inject the bearer token centrally (`FR-001`–`FR-004`).
- Decode the response envelope and discriminate failures (`FR-005`–`FR-009`).
- Classify transport errors (`FR-010`–`FR-012`).
- Use an explicit session configuration (`FR-013`).
- Log requests with PII masking (`FR-014`–`FR-016`).

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| Feature developer | Writes `Repository` implementations that call `NetworkService`. | Builds an `Endpoint`, receives a decoded value or a `NetworkError`. |
| Backend team | Owns the `ApiResponse` envelope and error codes. | Defines the envelope/error contract the layer models. |

### 2.4 Operating environment

- Platform: iOS, minimum version per the existing project target.
- Network: required for all business calls; `URLError` classifies offline/timeout.

### 2.5 Design and implementation constraints

- Swift + Clean Architecture, per `AGENTS.md`; the layer lives under `InnerLamp/Core/Networking/`.
- `NetworkServiceImpl` is an `actor` (concurrent calls serialize decode work without a caller-side lock).
- `Domain`/`Presentation` never import `Endpoint`/`NetworkService`/`NetworkError` directly — only a
  `Repository` does, and it maps `NetworkError` to its own `IL<Feature>Error`.
- Both public `NetworkService` method signatures are unchanged — the envelope is unwrapped inside the
  service.
- Core types are unprefixed (`NetworkService`, `Endpoint`, `APIConfig`), unlike the feature layers.

### 2.6 User documentation

**N/A** — this is internal infrastructure with no user-facing surface.

### 2.7 Assumptions and dependencies

- **Assumptions:**
  - Every business response uses the standard `ApiResponse` envelope; metadata endpoints (localization)
    may differ and use bare decoding.
  - The access token is stored in the Keychain under the key `"access_token"`.
- **Dependencies:**
  - `Core/Storage/KeychainService` (token), `Core/Logging/LoggingService` + `PIIMasker` (logging).
  - The backend contract in `Docs/Specs/API/openapi.yaml`.

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

**N/A** — this is a Core service with no UI.

#### 3.1.2 Hardware interfaces

**N/A** — this is an iOS application service with no custom hardware interface.

#### 3.1.3 Software interfaces

The layer models the backend's `ApiResponse` envelope (Go `ErrorDetail` struct mapped field-for-field to
Swift `APIEnvelope<T>` / `APIErrorDetail`). A feature `Repository` builds an `Endpoint` and calls
`NetworkService.request(endpoint:responseType:)`.

#### 3.1.4 Communication interfaces

- HTTPS + JSON. Requests carry `Content-Type`/`Accept: application/json` plus `X-Session-ID` /
  `X-Correlation-ID`. The auth header is attached centrally (§3.2).

### 3.2 Functional requirements

#### Auth header

**FR-001 — Attach stored token**
- **Priority:** Must
- **Description:** WHEN a request is sent and a valid access token exists in the Keychain, THE SYSTEM
  SHALL attach `Authorization: Bearer <token>` without the caller's `Endpoint` having to declare it.
- **Verification method:** Unit test (token present → header set).
- **Source:** EARS acceptance criterion (auth header).

**FR-002 — No token, still send**
- **Priority:** Must
- **Description:** WHEN no access token exists, THE SYSTEM SHALL send the request without an
  `Authorization` header — it SHALL NOT throw, block, or fabricate an empty token.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (no token).

**FR-003 — Explicit header wins**
- **Priority:** Must
- **Description:** WHEN an `Endpoint` explicitly declares its own `Authorization` value in `headers`,
  THE SYSTEM SHALL let that explicit value win over the stored token.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (explicit header).

**FR-004 — `requiresAuth == false` never injects**
- **Priority:** Must
- **Description:** WHEN an `Endpoint` declares `requiresAuth == false`, THE SYSTEM SHALL NOT attach any
  `Authorization` header, even if a valid token exists; `requiresAuth` defaults to `true`.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (public endpoint).

#### Response envelope

**FR-005 — 2xx envelope decode**
- **Priority:** Must
- **Description:** WHEN the server returns HTTP 2xx with a body matching the `ApiResponse` envelope, THE
  SYSTEM SHALL decode the envelope and hand the caller only the `data` field.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (envelope decode).

**FR-006 — 2xx `success = false`**
- **Priority:** Must
- **Description:** WHEN the envelope carries `success = false` on an HTTP 2xx response, THE SYSTEM SHALL
  treat the call as failed and throw an error carrying the envelope's `error.code`, `error.message`,
  `error.type`, and `details` when present.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (2xx success=false).

**FR-007 — 4xx/5xx envelope decode**
- **Priority:** Must
- **Description:** WHEN the server returns HTTP 4xx or 5xx whose body matches the envelope, THE SYSTEM
  SHALL throw an error carrying the envelope's `error.code`, `error.message`, `error.type`, and
  `details` when present, exactly as on the 2xx `success = false` path.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (4xx/5xx envelope).

**FR-008 — Unparseable error body**
- **Priority:** Must
- **Description:** WHEN an error response body does not parse as the envelope, THE SYSTEM SHALL throw
  `.serverError(statusCode:message:)` with `message` nil rather than crashing or attempting a second
  decode strategy.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (unparseable body).

**FR-009 — Bare decode for metadata endpoints**
- **Priority:** Must
- **Description:** WHEN an endpoint is a metadata endpoint (localization) that does not speak the
  envelope, THE SYSTEM SHALL decode that response bare, with no envelope unwrapping.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (bare decode).

#### Error classification

**FR-010 — No connectivity**
- **Priority:** Must
- **Description:** WHEN a request fails because the device has no connectivity, THE SYSTEM SHALL throw
  `NetworkError.noInternetConnection`.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (offline).

**FR-011 — Timeout**
- **Priority:** Must
- **Description:** WHEN a request exceeds its timeout, THE SYSTEM SHALL throw `NetworkError.timeout`.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (timeout).

**FR-012 — 401 → `.unauthorized`, no refresh**
- **Priority:** Must
- **Description:** WHEN the server returns HTTP 401, THE SYSTEM SHALL throw `NetworkError.unauthorized`
  and SHALL NOT attempt a token refresh itself.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (401).

#### Session and logging

**FR-013 — Explicit session configuration**
- **Priority:** Must
- **Description:** WHEN the app performs any request, THE SYSTEM SHALL use a `URLSession` built from an
  explicit, inspectable `URLSessionConfiguration` rather than `URLSession.shared`.
- **Verification method:** Code review + unit test.
- **Source:** EARS acceptance criterion (session config).

**FR-014 — One log record per request**
- **Priority:** Must
- **Description:** WHEN a request completes, THE SYSTEM SHALL emit one log record through
  `LoggingService` containing the HTTP method, path, status code, and duration.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (request logging).

**FR-015 — PII masking**
- **Priority:** Must
- **Description:** WHEN a request or response contains a credential (bearer token, password field), THE
  SYSTEM SHALL route it through `PIIMasker` before it reaches any log destination.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (PII masking).

**FR-016 — Failure logged as classification**
- **Priority:** Must
- **Description:** WHEN a request fails, THE SYSTEM SHALL log the failure classification (`NetworkError`
  case or `ApiResponse.error.code`) — not the raw response body.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (failure classification).

### 3.3 Performance requirements

- **NFR-001 — Timeouts:** 30s request timeout / 60s resource timeout, `waitsForConnectivity = false`
  (configured in `NetworkConfiguration`).

### 3.4 Logical database requirements

- **Client-side:** no persistence in this layer; it reads the access token from the Keychain via
  `AuthTokenProviding`.

### 3.5 Design constraints

- The envelope is unwrapped **inside** `NetworkServiceImpl` so no feature `Repository` changes
  (`No caller-visible signature change`).
- `NetworkError` must stay `Sendable` (it crosses the `NetworkServiceImpl` actor boundary); `AnyCodable`
  is `@unchecked Sendable` for this reason.
- Never import `Endpoint`/`NetworkService`/`NetworkError` in `Domain`/`Presentation`.

### 3.6 Software system attributes

- **Reliability:** unparseable bodies and transport failures map to explicit `NetworkError` cases; no
  crash and no second decode strategy.
- **Availability:** `URLError` classification is the single source of truth for "no internet".
- **Security:** bearer tokens are injected centrally and masked in logs; `requiresAuth == false`
  guarantees a public endpoint never carries a token; PII is masked before logging.
- **Maintainability:** one place (the `Repository`) maps `NetworkError` to `IL<Feature>Error`; the
  transport-agnostic boundary keeps future transport changes scoped.
- **Portability:** the envelope/log/auth policy is transport-shaped; the isolation it establishes is
  what makes a future gRPC migration a scoped rewrite.

---

## 4. Verification & traceability

### 4.1 Verification approach

- **Unit tests** (`NetworkServiceTests`, 16 cases) covering the envelope matrix (success, `success:
  false`, unparseable body, absent `data`, `.bare` bypass, 401), the auth-header matrix, and logging
  (one record, token never appears, failure classified).
- **Code review** for the `Sendable`/`AnyCodable` rationale and the transport-agnostic boundary.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Attach stored token | → spec-writer | TBD |
| FR-002 | No token, still send | → spec-writer | TBD |
| FR-003 | Explicit header wins | → spec-writer | TBD |
| FR-004 | `requiresAuth == false` | → spec-writer | TBD |
| FR-005 | 2xx envelope decode | → spec-writer | TBD |
| FR-006 | 2xx success=false | → spec-writer | TBD |
| FR-007 | 4xx/5xx envelope decode | → spec-writer | TBD |
| FR-008 | Unparseable error body | → spec-writer | TBD |
| FR-009 | Bare decode | → spec-writer | TBD |
| FR-010 | No connectivity | → spec-writer | TBD |
| FR-011 | Timeout | → spec-writer | TBD |
| FR-012 | 401 → unauthorized | → spec-writer | TBD |
| FR-013 | Explicit session config | → spec-writer | TBD |
| FR-014 | One log record | → spec-writer | TBD |
| FR-015 | PII masking | → spec-writer | TBD |
| FR-016 | Failure classification | → spec-writer | TBD |
| NFR-001 | Timeouts | → spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: whether anything in the app refreshes an expired token on 401, and if so whether that
> lives in `Core/Networking` or in the feature that receives the 401 — blocks defining what happens after
> `.unauthorized` is thrown.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Surface the envelope's `details`? | Yes — `[String: AnyCodable]?` on `NetworkError.apiError` (v1.3) | 2026-09-15 |
| Is `data` optional? | Yes — `T?`, matching `omitempty`; absent data on success throws `.noData` | 2026-09-15 |
| Timeout values | 30s request / 60s resource, `waitsForConnectivity = false` | 2026-09-15 |
| Keychain key for the token | `"access_token"` | 2026-09-15 |
| Failure discriminator | `error.code` (not the message string) | 2026-09-15 |
| Which endpoints speak the envelope | All business APIs; metadata endpoints may use bare decode | 2026-09-15 |
