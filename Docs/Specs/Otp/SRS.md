# Software Requirements Specification — Otp

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | Otp |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-09-27 |
| Status | retroactive — reconstructed from `requirements.md` / `design.md` / `tasks.md` |
| Owner / author | il-ba (Business Analyst) |
| Downstream handoff | `il-spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

This document is the Software Requirements Specification for the **Otp** feature of InnerLamp. It
defines — for the PM and engineering — *what* the feature must do, at business level, in IEEE
29148-2018 form. It is reconstructed retroactively from the implemented feature and its engineering
spec.

### 1.2 Scope

**In scope:**

- The OTP screen where a new visitor enters the 6-digit code sent to their phone.
- The verify call (`POST /v1/auth/register/verify-otp`) that creates the account and stores the session.
- The resend call (`POST /v1/auth/resend-otp`) with server-driven timing.
- The voice-call banner (deferred — no backend call).

**Out of scope:**

- Login (`POST /v1/auth/login`) and token refresh (`POST /v1/auth/refresh`) — separate features; Otp only
  stores the refresh token.
- ForgotPassword's own OTP-request path (its OTP entry reuses this screen).
- The voice-call OTP channel.

### 1.3 Product overview

InnerLamp is a Buddhist companion app (UIKit, Swift, Clean Architecture + MVVM-C). Otp is the second
half of registration: after `request-otp` (SignUp), Otp verifies the 6-digit code, creates the account,
signs the user in, and continues into the app.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| OTP | One-time password — the 6-digit code sent by SMS. |
| Verify | `POST /v1/auth/register/verify-otp` — the call that creates the account and returns the first session. |
| Resend | `POST /v1/auth/resend-otp` (`purpose = "register"`) — the call that re-sends the code. |
| Timing entity | `ILOtpTimingEntity` — `expiresInSeconds`, `resendAfterSeconds` returned by the server. |

### 1.5 References

- `Docs/Specs/Otp/requirements.md`, `design.md`, `tasks.md`, `changelog.md`.
- `Docs/Specs/API/openapi.yaml` (v3.9) — `POST /v1/auth/register/verify-otp` and `POST /v1/auth/resend-otp`.
- `Docs/Specs/SignUp/` — the preceding `request-otp` call.

### 1.6 Document organization

§2 describes the feature at a product level. §3 gives the functional (`FR-*`) and non-functional
(`NFR-*`) requirements. §4 defines verification and the traceability matrix. §5 lists open questions.

---

## 2. Overall description

### 2.1 Product perspective

This is a **new feature** within InnerLamp that completes the registration flow started by SignUp. It is
not an isolated section: `ILOtpCoordinator` is pushed on top of the existing stack by `AppCoordinator`
(from SignUp or ForgotPassword) and finishes on success or back. Its external systems are the two
confirmed OTP endpoints.

### 2.2 Product functions

- Show the OTP screen with server-seeded timing (`FR-001`, `FR-002`).
- Verify the code and store the session (`FR-003`, `FR-004`).
- Resend the code and restart the countdown (`FR-005`, `FR-006`).
- Defer the voice-call channel (`FR-007`).
- Return to the previous screen (`FR-008`).

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| New visitor | Just submitted the SignUp form and received an OTP. | Enters the code, resends as needed, and continues into the app. |

### 2.4 Operating environment

- Platform: iOS, minimum version per the existing project target.
- Devices: iPhone (primary).
- Network: required for verify/resend.

### 2.5 Design and implementation constraints

- Swift + UIKit (100% programmatic UI), Clean Architecture + MVVM-C + Coordinator, per `AGENTS.md`.
- Manual DI via `DIContainer`.
- No hardcoded user-facing text; the countdown/expiry copy is seeded from the server, not a hardcoded
  constant.
- No UIKit import in ViewModels/Domain.

### 2.6 User documentation

**N/A** — this is a consumer app feature; no separate manual is produced.

### 2.7 Assumptions and dependencies

- **Assumptions:**
  - A live `pending_registration` exists for the number when the screen is reached.
  - The server's `expires_in_seconds` / `resend_after_seconds` drive the countdown/expiry copy.
- **Dependencies:**
  - `Docs/Specs/API/openapi.yaml` (v3.9) — confirmed verify/resend contract.
  - `KeychainService`, `ILUserRepository` — session persistence.
  - `Docs/Specs/SignUp/` — passes the phone number + timing to this screen.

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

A single screen: header with title/subtitle and "Đổi số" (change number), a 6-digit code input, a
"Gửi lại" (resend) row, the voice-call banner, and a footer with the "Xác nhận" (confirm) button and an
expiry label. Reuses `ILCodeInputView` and feature-scoped `ILOtpResendRowView` / `ILOtpVoiceCallBannerView`.

#### 3.1.2 Hardware interfaces

**N/A** — this is an iOS application feature with no custom hardware interface.

#### 3.1.3 Software interfaces

Confirmed contract (`Docs/Specs/API/openapi.yaml` v3.9):

| Route | Request | Success data | Confirmed failures |
|---|---|---|---|
| `POST /v1/auth/register/verify-otp` | `phone_number`, `otp_code` | `201` → {access_token, refresh_token, user} | `400` OTP_INVALID / OTP_EXPIRED / PENDING_REGISTRATION_EXPIRED; `409` PHONE_TAKEN / EMAIL_TAKEN; `429` OTP_LOCKED; `500` INTERNAL_ERROR |
| `POST /v1/auth/resend-otp` | `phone_number`, `purpose = "register"` | `200` → {message, expires_in_seconds, resend_after_seconds} | `400` OTP_INVALID / PENDING_REGISTRATION_EXPIRED; `429` OTP_RESEND_TOO_SOON / OTP_LOCKED / OTP_SEND_LIMITED; `500` SMS_SEND_FAILED / INTERNAL_ERROR |

Both public (`requiresAuth = false`), speaking the standard `ApiResponse` envelope.

#### 3.1.4 Communication interfaces

- HTTPS + JSON through the shared `ApiResponse` envelope and `NetworkService`.

### 3.2 Functional requirements

**FR-001 — Load state**
- **Priority:** Must
- **Description:** WHEN the OTP screen loads, THE SYSTEM SHALL show the phone number the code was sent
  to, a 6-digit code input, a "Gửi lại" row, the voice-call banner, and a "Xác nhận" button disabled
  until exactly 6 digits are entered.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (load state).

**FR-002 — Server-seeded timing**
- **Priority:** Must
- **Description:** WHEN the screen loads, THE SYSTEM SHALL seed the "Gửi lại" countdown and the
  code-expiry message from the server's `resend_after_seconds` / `expires_in_seconds` returned by the
  preceding `request-otp` call, instead of the previously hardcoded values.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (timing).

**FR-003 — Verify success**
- **Priority:** Must
- **Description:** WHEN the user taps "Xác nhận" with a complete 6-digit code, THE SYSTEM SHALL call
  `POST /v1/auth/register/verify-otp` and, on success (HTTP 201), store the `access_token`, `refresh_token`,
  and `user` locally and navigate to the main app.
- **Verification method:** Unit test (session persistence) + manual QA.
- **Source:** EARS acceptance criterion (verify success).

**FR-004 — Verify failure**
- **Priority:** Must
- **Description:** WHEN verify fails, THE SYSTEM SHALL stay on the screen, keep the entered code, and
  show the corresponding error (`OTP_INVALID`, `OTP_EXPIRED`, `PENDING_REGISTRATION_EXPIRED`,
  `PHONE_TAKEN`/`EMAIL_TAKEN`, `OTP_LOCKED`, `INTERNAL_ERROR`, offline/timeout).
- **Verification method:** Unit test (error mapping).
- **Source:** EARS acceptance criterion (verify failure).

**FR-005 — Resend**
- **Priority:** Must
- **Description:** WHEN the user taps "Gửi lại" and the cooldown has elapsed, THE SYSTEM SHALL call
  `POST /v1/auth/resend-otp` with `purpose = "register"` and restart the countdown and expiry message
  from the returned `resend_after_seconds` / `expires_in_seconds`.
- **Verification method:** Unit test (resend timing).
- **Source:** EARS acceptance criterion (resend).

**FR-006 — Resend failure**
- **Priority:** Must
- **Description:** WHEN a resend fails, THE SYSTEM SHALL stay on the screen, keep the code, and show the
  corresponding error (`OTP_INVALID`, `PENDING_REGISTRATION_EXPIRED`, `OTP_RESEND_TOO_SOON`,
  `OTP_LOCKED`/`OTP_SEND_LIMITED`, `SMS_SEND_FAILED`/`INTERNAL_ERROR`).
- **Verification method:** Unit test (error mapping).
- **Source:** EARS acceptance criterion (resend failure).

**FR-007 — Voice-call banner (deferred)**
- **Priority:** Must
- **Description:** WHEN the user taps the voice-call banner, THE SYSTEM SHALL NOT call the backend (the
  confirmed `resend-otp` contract has no channel field).
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (voice banner).

**FR-008 — Back / change number**
- **Priority:** Must
- **Description:** WHEN the user taps back or "Đổi số", THE SYSTEM SHALL return to the previous screen
  (SignUp / ForgotPassword) without changing any of its state.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (back).

### 3.3 Performance requirements

- **NFR-001 — Verify/resend responsiveness:** the calls should complete within a target to be confirmed;
  the countdown/expiry must reflect the server's returned values, not a hardcoded constant.

### 3.4 Logical database requirements

- **Client-side:** on verify success, the `access_token` is stored in the Keychain (under
  `KeychainAuthTokenProviding.accessTokenKey`), the `refresh_token` under a dedicated key, and the
  `user` via `ILUserRepository` (Core Data).

### 3.5 Design constraints

- Follow the InnerLamp Design System tokens; reuse `ILCodeInputView`.
- Follow Clean Architecture: `ILOtpTimingEntity` / `ILAuthSessionEntity` (Domain) vs `ILOtpStateModel`
  (Presentation); DTO + Mapper + Endpoints in Data. No UIKit import in Domain/StateModel.
- `ILOtpError.from(_:operation:)` is operation-aware (`OTP_INVALID` means a wrong code on verify but "no
  pending registration" on resend).

### 3.6 Software system attributes

- **Reliability:** failure stays on screen with the code preserved; persistence failure surfaces as
  `storageFailed` (the account is already created at that point).
- **Availability:** the screen loads locally; verify/resend degrade to the shared error states.
- **Security:** access/refresh tokens are stored in the Keychain; no PII is logged.
- **Maintainability:** each requirement maps to a unit-testable UseCase/ViewModel seam.
- **Portability:** pure-Domain code is `Foundation`-only.

---

## 4. Verification & traceability

### 4.1 Verification approach

- **Unit tests** (`ILOtpViewModelTests`, `ILOtpUseCaseTests`, `ILOtpRepositoryTests`) covering session
  persistence, resend timing, voice-call refusal, and the error mapping (verify/resend-aware).
- **Manual QA** against a real/staging backend once available (success, `OTP_INVALID`, `OTP_EXPIRED`,
  `PENDING_REGISTRATION_EXPIRED`, `OTP_LOCKED`, resend cooldown, offline/timeout).

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Load state | → il-spec-writer | TBD |
| FR-002 | Server-seeded timing | → il-spec-writer | TBD |
| FR-003 | Verify success | → il-spec-writer | TBD |
| FR-004 | Verify failure | → il-spec-writer | TBD |
| FR-005 | Resend | → il-spec-writer | TBD |
| FR-006 | Resend failure | → il-spec-writer | TBD |
| FR-007 | Voice banner | → il-spec-writer | TBD |
| FR-008 | Back | → il-spec-writer | TBD |
| NFR-001 | Verify/resend responsiveness | → il-spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: whether/how the backend supports a voice-call OTP channel — `ResendOTPRequest` carries
> only `phone_number` + `purpose`, so no voice variant exists — blocks implementing the banner beyond a
> "not available yet" message.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Where to store tokens/user from verify? | Keychain (access + refresh) + `ILUserRepository` | 2026-09-23 |
| Use server timing or hardcoded? | Use the server's `expires_in_seconds` / `resend_after_seconds` | 2026-09-23 |
| Voice-call banner behavior | Deferred — must not call the backend until a voice channel is confirmed | 2026-09-23 |
