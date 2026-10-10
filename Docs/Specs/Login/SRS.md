# Software Requirements Specification — Login

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | Login |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-09-27 |
| Status | retroactive — reconstructed from `requirements.md` / `design.md` / `tasks.md` |
| Owner / author | ba-writer (Business Analyst) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

This document is the Software Requirements Specification for the **Login** feature of InnerLamp. It
defines — for the PM and engineering — *what* the feature must do, at business level, in IEEE
29148-2018 form. It is reconstructed retroactively from the already-implemented feature and its
engineering spec.

### 1.2 Scope

**In scope:**

- A screen where a returning user (or visitor from Onboarding / SignUp) signs in with phone number +
  password, or continues as a guest.
- Phone entry with the shared country picker, password entry, inline field errors, and a submit CTA.
- Navigation to Main (success/guest), SignUp, ForgotPassword, and Onboarding.

**Out of scope:**

- Password recovery — owned by the ForgotPassword feature.
- Account creation — owned by the SignUp feature.
- The actual authentication request (`login`) — the use case method is a one-line stub today; the
  Data-layer implementation depends on the (already confirmed) contract.

### 1.3 Product overview

InnerLamp is a Buddhist companion app (UIKit, Swift, Clean Architecture + MVVM-C). Login is a
**cross-section navigation** (Onboarding ↔ SignUp ↔ ForgotPassword ↔ Main) that lets a returning user
reach the main app, or a visitor continue as a guest.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| E.164 | The international phone-number format; the client sends a grouped, dial-code-prefixed display string that the server normalizes to E.164. |
| Guest preview | Continuing into the main app without authenticating ("Xem trước, đăng nhập sau"). |
| Login lock | After 5 consecutive failed logins, the number is locked for 15 minutes (`LOGIN_LOCKED`). |

### 1.5 References

- `Docs/Specs/Login/requirements.md`, `design.md`, `tasks.md`, `changelog.md`.
- `Docs/Specs/API/openapi.yaml` (v3.9) — `POST /v1/auth/login` (confirmed contract).
- `Docs/Specs/SignUp/`, `Docs/Specs/ForgotPassword/`, `Docs/Specs/Otp/`.
- `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`, block `isLogin`.

### 1.6 Document organization

§2 describes the feature at a product level. §3 gives the functional (`FR-*`) and non-functional
(`NFR-*`) requirements. §4 defines verification and the traceability matrix. §5 lists open questions.

---

## 2. Overall description

### 2.1 Product perspective

This is a **new feature** within InnerLamp, following the canonical `Onboarding` / `SignUp` shape. It is
a cross-section navigation owned by `AppCoordinator` (via `showLogin()`), set as the root of its own
stack so "Tạo tài khoản mới" pushes SignUp on top of Login. Its external system is the **login
endpoint** (`POST /v1/auth/login`), whose contract is confirmed but whose Data layer is not yet built.

### 2.2 Product functions

- Show the Login screen with empty phone/password fields and an enabled submit (`FR-001`).
- Let the user pick a country and edit fields without cursor jumps (`FR-002`, `FR-003`).
- Validate and submit, routing on success/failure (`FR-004`, `FR-005`).
- Guard against double submission (`FR-006`).
- Navigate to Onboarding, SignUp, ForgotPassword, and guest preview (`FR-007`–`FR-010`).

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| Returning user | Signs in with phone + password. | Has registered credentials; reaches Main on success. |
| Visitor | Comes from Onboarding/SignUp, or chooses guest preview. | May continue into the app without authenticating. |

### 2.4 Operating environment

- Platform: iOS, minimum version per the existing project target.
- Devices: iPhone (primary).
- Network: the submit path requires network (the real call is currently a stub).

### 2.5 Design and implementation constraints

- Swift + UIKit (100% programmatic UI), Clean Architecture + MVVM-C + Coordinator, per `AGENTS.md`.
- Manual DI via `DIContainer`; the coordinator is owned by `AppCoordinator`.
- No hardcoded user-facing text — strings come from the JSON localization system (`"login.*"` keys); no
  inline font sizes or colors — use `ILTypography`, `ILColors`, `ILMetrics`.
- No UIKit import in ViewModels/Domain.

### 2.6 User documentation

**N/A** — this is a consumer app feature; no separate manual is produced.

### 2.7 Assumptions and dependencies

- **Assumptions:**
  - The server is the authority on credentials; login enforces "non-empty password" only (no minimum
    length).
  - The SMS-code login ("Đăng nhập bằng mã SMS") will eventually route through the OTP feature or its
    own flow.
- **Dependencies:**
  - `Docs/Specs/API/openapi.yaml` — confirmed `POST /v1/auth/login` contract.
  - The Data layer (`ILLoginRepositoryImpl`, DTO, Mapper, Endpoint) — not yet built.
  - `Docs/Specs/Otp/` — the OTP feature that may serve SMS-code login.

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

A single screen: header with lamp glow, title/subtitle, a phone field (country flag + dial code +
national number), a password field (secure, with a "Quên?" trailing action), the login CTA ("Đăng
nhập"), an SMS-code CTA ("Đăng nhập bằng mã SMS"), and a footer (divider + "Tạo tài khoản mới" +
"Xem trước, đăng nhập sau"). Reuses `ILNavBar`, `ILPhoneField`, `ILField`, `ILButton`,
`ILLampGlowView`, `ILCountryPickerViewController`, `ILDividerRow`.

#### 3.1.2 Hardware interfaces

**N/A** — this is an iOS application feature with no custom hardware interface.

#### 3.1.3 Software interfaces

The login endpoint is **confirmed** in `Docs/Specs/API/openapi.yaml` v3.9:

| Route | Request | Success data | Confirmed failures |
|---|---|---|---|
| `POST /v1/auth/login` | `phone_number`, `password` (non-empty only), `device` {platform, device_model, os_version?, app_version?, device_name?} | `VerifyOTPData` {access_token, refresh_token, user} | `400` VALIDATION_ERROR / INVALID_PHONE / INVALID_PASSWORD / INVALID_DEVICE; `401` INVALID_CREDENTIALS (5 fails → 15-min lock); `413` PAYLOAD_TOO_LARGE; `429` LOGIN_LOCKED (`details.locked_until`); `500` INTERNAL_ERROR |

Public (`requiresAuth = false`). Only the Data-layer implementation is pending, not the contract.

#### 3.1.4 Communication interfaces

- HTTPS + JSON through the shared `ApiResponse` envelope and `NetworkService`.

### 3.2 Functional requirements

**FR-001 — Load state**
- **Priority:** Must
- **Description:** WHEN the Login screen loads, THE SYSTEM SHALL show a phone field (country flag + dial
  code + national number) and a password field, both empty, with the default country selected and the
  submit button enabled.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (load state).

**FR-002 — Country picker**
- **Priority:** Must
- **Description:** WHEN the user taps the country flag/dial code, THE SYSTEM SHALL present the shared
  country picker (search + list of 12 countries); selecting a country SHALL update the dial code shown
  in the phone field.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (country picker).

**FR-003 — Field editing**
- **Priority:** Must
- **Description:** WHEN the user types into the phone or password field, THE SYSTEM SHALL NOT re-render
  the field's text (to avoid moving the cursor) and SHALL clear any previously shown field error for
  that field.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (field editing).

**FR-004 — Submit validation**
- **Priority:** Must
- **Description:** WHEN the user taps "Đăng nhập" with an empty or invalid phone number (below the
  selected country's minimum digit count) or an empty password, THE SYSTEM SHALL show an inline error on
  the offending field and SHALL NOT call the login use case. Password is validated as "non-empty only".
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (submit validation).

**FR-005 — Submit**
- **Priority:** Must
- **Description:** WHEN the user taps "Đăng nhập" with all fields valid, THE SYSTEM SHALL show a loading
  state and call the login use case with the phone number in grouped, dial-code-prefixed display format
  (`+84 912 345 678`), then: on success, navigate to the main app; on failure, show the returned error
  message and stay on the Login screen with no navigation event.
- **Verification method:** Unit test (success/failure) + manual QA.
- **Source:** EARS acceptance criterion (submit).

**FR-006 — Double-submit guard**
- **Priority:** Must
- **Description:** WHEN a login request is already in flight, THE SYSTEM SHALL ignore a second tap on
  "Đăng nhập" and SHALL NOT submit the form twice.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (double-submit).

**FR-007 — Back to Onboarding**
- **Priority:** Must
- **Description:** WHEN the user taps the back control, THE SYSTEM SHALL navigate to Onboarding.
- **Verification method:** Unit test (nav event).
- **Source:** EARS acceptance criterion (back).

**FR-008 — Create account**
- **Priority:** Must
- **Description:** WHEN the user taps "Tạo tài khoản mới", THE SYSTEM SHALL navigate to the SignUp
  screen, keeping the Login screen on the navigation stack underneath.
- **Verification method:** Unit test (nav event).
- **Source:** EARS acceptance criterion (create account).

**FR-009 — Forgot password**
- **Priority:** Must
- **Description:** WHEN the user taps "Quên?" next to the password field, THE SYSTEM SHALL navigate to
  the ForgotPassword screen.
- **Verification method:** Unit test (nav event).
- **Source:** EARS acceptance criterion (forgot).

**FR-010 — Guest preview**
- **Priority:** Must
- **Description:** WHEN the user taps "Xem trước, đăng nhập sau" (guest preview), THE SYSTEM SHALL
  navigate to the main app without authenticating.
- **Verification method:** Unit test (nav event).
- **Source:** EARS acceptance criterion (guest preview).

### 3.3 Performance requirements

- **NFR-001 — Submit responsiveness:** the login call should complete within a target to be confirmed;
  the 429 lock timing must be read from `details.locked_until` and surfaced to the user.
  > ⚠️ Not confirmed: the concrete response-time budget — blocks the performance test threshold.

### 3.4 Logical database requirements

- **Client-side:** the login result (access token, refresh token, user) is stored in the Keychain /
  Core Data by the session persistence path (shared with Otp/SignUp via `ILAuthSessionEntity`). Login
  itself does not persist credentials.

### 3.5 Design constraints

- Follow the InnerLamp Design System tokens and reuse the existing auth components.
- Follow Clean Architecture: `ILLoginEntity` (pure business fields, Domain) vs `ILLoginStateModel`
  (UI-only state, Presentation). No UIKit import in Domain/StateModel.
- `ILLoginError` must be extended to cover the confirmed contract's failure matrix (see §5).

### 3.6 Software system attributes

- **Reliability:** double-submit guard and failure-stays-on-screen; no crash on malformed input.
- **Availability:** the screen loads and validates locally; the submit path degrades to an error state
  until the Data layer is built.
- **Security:** the password is handled as a credential and must be masked in logs (PII-masking rule);
  the access token is stored in the Keychain; the login endpoint is public (`requiresAuth = false`).
- **Maintainability:** each requirement maps to a unit-testable ViewModel seam.
- **Portability:** pure-Domain code is `Foundation`-only.

---

## 4. Verification & traceability

### 4.1 Verification approach

- **Unit tests** (`XCTest`) for the ViewModel via `MockILLoginUseCase`: initial state, country change,
  the four nav events, invalid-form no-call, valid-form success, and login-failure stays-on-screen.
- **Manual QA** for the visual layout and the country picker interaction.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Load state | → spec-writer | TBD |
| FR-002 | Country picker | → spec-writer | TBD |
| FR-003 | Field editing | → spec-writer | TBD |
| FR-004 | Submit validation | → spec-writer | TBD |
| FR-005 | Submit | → spec-writer | TBD |
| FR-006 | Double-submit guard | → spec-writer | TBD |
| FR-007 | Back to Onboarding | → spec-writer | TBD |
| FR-008 | Create account | → spec-writer | TBD |
| FR-009 | Forgot password | → spec-writer | TBD |
| FR-010 | Guest preview | → spec-writer | TBD |
| NFR-001 | Submit responsiveness | → spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: whether the SMS-code login should reuse the OTP feature's screen/flow (the contract's
> `ResendOTPRequest.purpose` enum lists `login`, but the note states "US-001 only implements register;
> the other three return UNSUPPORTED_OTP_PURPOSE") — blocks the SMS-code login (Phase 4).

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Is email part of login? | No — phone + password only | 2026-09-27 |
| Is a password minimum enforced at login? | No — non-empty only; the server is the authority | 2026-09-21 |
