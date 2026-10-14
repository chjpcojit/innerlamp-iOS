# Software Requirements Specification — SignUp

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | SignUp |
| Product | InnerLamp |
| Version | 0.2 (draft) |
| Last updated | 2026-10-11 |
| Status | retroactive — reconstructed from `requirements.md` / `design.md` / `tasks.md` |
| Owner / author | ba-writer (Business Analyst) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

This document is the Software Requirements Specification for the **SignUp** feature of InnerLamp. It
defines — for the PM and engineering — *what* the feature must do, at business level, in IEEE
29148-2018 form. It is reconstructed retroactively from the already-implemented feature and its
engineering spec.

### 1.2 Scope

**In scope:**

- A registration screen where a new visitor enters a required full name, a dharma name (or nickname), an
  optional ordination place, a phone number, a required email, and a password (min 8), then requests an OTP.
- Live field feedback (phone validity, email format, password strength) and inline validation errors.
- The Terms of Service / Privacy Policy side-navigation (public URL in a web view).

**Out of scope:**

- Account creation itself — the account is created by the follow-on `POST /v1/auth/register/verify-otp`
  call, owned by the OTP feature, not by SignUp.

### 1.3 Product overview

InnerLamp is a Buddhist companion app (UIKit, Swift, Clean Architecture + MVVM-C). SignUp is a
**cross-section navigation** (Onboarding → SignUp → OTP/Login) that collects the registration fields and
starts the OTP flow; the email lets the user receive donation receipts later.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Full name (Họ và tên) | The user's real name — required, free-text, sent as `full_name`. |
| Dharma name (Pháp danh) | The user's Buddhist name or nickname; free-text, with a "Gợi ý" button that cycles a fixed suggestion list. |
| Ordination place (Nơi xuất gia) | The temple/monastery where a monastic was ordained — optional, picked from the server's temple list (`GET /v1/temples/options`) and sent as `ordination_temple_id`. |
| E.164 | The international phone format; the client sends a grouped, dial-code-prefixed display string the server normalizes to E.164. |
| OTP | One-time password sent by SMS to verify the phone number. |

### 1.5 References

- `Docs/Specs/SignUp/requirements.md`, `design.md`, `tasks.md`, `changelog.md`.
- `Docs/Specs/API/openapi.yaml` (v3.9) — `POST /v1/auth/register/request-otp`.
- `Docs/Specs/Otp/` — the follow-on verify/resend calls.
- `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`, block `isSignup`.

### 1.6 Document organization

§2 describes the feature at a product level. §3 gives the functional (`FR-*`) and non-functional
(`NFR-*`) requirements. §4 defines verification and the traceability matrix. §5 lists open questions.

---

## 2. Overall description

### 2.1 Product perspective

This is a **new feature** within InnerLamp, matching the canonical `Onboarding` shape. It is a
cross-section navigation owned by `AppCoordinator` (`showSignUp()`), pushed onto the Onboarding stack.
Its external system is the confirmed `POST /v1/auth/register/request-otp` endpoint, plus two public
legal-content URLs (ToS / Privacy).

### 2.2 Product functions

- Show the form with an empty required full name, a pre-filled dharma name and a disabled submit (`FR-001`, `FR-020`).
- Provide dharma-name suggestion, country picker, and live field feedback (`FR-002`–`FR-007`).
- Validate and submit the form (`FR-008`–`FR-012`).
- Navigate to Login, Onboarding, and the legal screens (`FR-013`–`FR-019`).

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| New visitor | Comes from Onboarding to create an account. | Enters registration fields and requests an OTP. |
| Monastic user (optional) | May provide an ordination place. | The "Nơi xuất gia" field is optional for everyone. |

### 2.4 Operating environment

- Platform: iOS, minimum version per the existing project target.
- Devices: iPhone (primary).
- Network: required for the `request-otp` call and for loading the legal web pages.

### 2.5 Design and implementation constraints

- Swift + UIKit (100% programmatic UI), Clean Architecture + MVVM-C + Coordinator, per `AGENTS.md`.
- Manual DI via `DIContainer`; the coordinator is owned by `AppCoordinator`.
- No hardcoded user-facing text — strings come from the JSON localization system (`"signup.*"` keys); no
  inline font sizes or colors.
- No UIKit import in ViewModels/Domain.

### 2.6 User documentation

**N/A** — this is a consumer app feature; no separate manual is produced.

### 2.7 Assumptions and dependencies

- **Assumptions:**
  - The server checks phone/email uniqueness as part of `request-otp` (no separate "check exists" call).
  - The server normalizes the grouped display phone string to E.164.
- **Dependencies:**
  - `Docs/Specs/API/openapi.yaml` (v3.9) — confirmed `request-otp` contract.
  - `Docs/Specs/Otp/` — the follow-on verify/resend calls.
  - The ToS / Privacy Policy public URLs (not yet provided — see §5).

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

A single scrolling screen: full-name field (`ILField`, first), dharma-name suggestion field, ordination-place field, phone field (with
country picker), email field, password field (with strength meter), a terms checkbox row, and the submit
CTA ("Gửi mã xác thực"). Reuses `ILCheckboxRow`, `ILStrengthMeterView`, `ILPhoneField`,
`ILCountryPickerViewController`, `ILField`, `ILButton`, plus a `ILLegalContentViewController` (not yet
built) for the legal screens.

#### 3.1.2 Hardware interfaces

**N/A** — this is an iOS application feature with no custom hardware interface.

#### 3.1.3 Software interfaces

Confirmed contract (`Docs/Specs/API/openapi.yaml` v3.9):

| Route | Request | Success data | Confirmed failures |
|---|---|---|---|
| `POST /v1/auth/register/request-otp` | `full_name` (⚠️ not yet in backend contract — AS-SignUp-004), `dharma_name`, `ordination_temple_id` (optional), `phone_number`, `email`, `password` | `message`, `expires_in_seconds` (90), `resend_after_seconds` (60) | `400` VALIDATION_ERROR / INVALID_EMAIL / INVALID_PHONE / INVALID_PASSWORD / INVALID_DHARMA_NAME / INVALID_TEMPLE; `409` PHONE_TAKEN / EMAIL_TAKEN; `413` PAYLOAD_TOO_LARGE; `429` OTP_LOCKED / OTP_RESEND_TOO_SOON / OTP_SEND_LIMITED; `500` SMS_SEND_FAILED / INTERNAL_ERROR |

Public (`requiresAuth = false`), speaking the standard `ApiResponse` envelope. Account creation is **not**
here — it happens in `verify-otp` (Otp).

#### 3.1.4 Communication interfaces

- HTTPS + JSON through the shared `ApiResponse` envelope and `NetworkService`.
- The ToS / Privacy Policy screens load content from a **public URL** in a `WKWebView`.

### 3.2 Functional requirements

**FR-001 — Load state**
- **Priority:** Must
- **Description:** WHEN the SignUp screen loads, THE SYSTEM SHALL show the full-name field empty,
  pre-fill the display-name field with the first suggested dharma name and show the submit button
  disabled until the terms checkbox is checked.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (load state).

**FR-002 — Dharma-name suggestion**
- **Priority:** Must
- **Description:** WHEN the user taps "Gợi ý" (suggest), THE SYSTEM SHALL cycle through a fixed list of
  10 dharma name suggestions; the user MAY also type the dharma name freely, and a typed value SHALL be
  kept until the next "Gợi ý" tap.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (dharma name).

**FR-003 — Country picker**
- **Priority:** Must
- **Description:** WHEN the user taps the country flag/dial code, THE SYSTEM SHALL present a country
  picker (search + list of 12 countries); selecting a country SHALL update the dial code and the phone
  validity hint immediately.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (country picker).

**FR-004 — Phone validity hint**
- **Priority:** Must
- **Description:** WHEN the user types a phone number, THE SYSTEM SHALL show a live valid/invalid hint
  based on the selected country's minimum national digit count (not hardcoded to Vietnam).
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (phone hint).

**FR-005 — Ordination place (optional)**
- **Priority:** Must
- **Description:** WHEN the user opens the optional "Nơi xuất gia" picker, THE SYSTEM SHALL load temples
  from `GET /v1/temples/options` (paged, server-side `?q=` search) with "Chưa xuất gia" first; WHEN the
  user picks a temple, THE SYSTEM SHALL send its id as `ordination_temple_id`, and for "Chưa xuất gia" or
  a proposal pending approval SHALL omit the field. The choice SHALL NOT block submit. Details:
  `requirements.md` v1.14.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (ordination place).

**FR-006 — Email validation**
- **Priority:** Must
- **Description:** WHEN the user types an email (required field), THE SYSTEM SHALL show a live format
  hint only while the field is non-empty (error border when invalid, success state when valid).
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (email).

**FR-007 — Password strength**
- **Priority:** Must
- **Description:** WHEN the user types a password, THE SYSTEM SHALL show a live 3-segment strength meter
  (weak / fair / strong); a password shorter than 8 characters SHALL be scored "weak".
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (password strength).

**FR-008 — Terms checkbox**
- **Priority:** Must
- **Description:** WHEN the user taps the terms checkbox, THE SYSTEM SHALL enable/disable the submit
  button accordingly.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (terms).

**FR-009 — Submit validation**
- **Priority:** Must
- **Description:** WHEN the user taps "Gửi mã xác thực" with invalid or missing fields (empty full name,
  empty/bad email,
  phone below the country minimum, password under 8), THE SYSTEM SHALL show an inline error per field
  and SHALL NOT call the backend.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (submit validation).

**FR-010 — Submit**
- **Priority:** Must
- **Description:** WHEN the user taps submit with all fields valid, THE SYSTEM SHALL show a loading
  state and call `POST /v1/auth/register/request-otp`, then: on success (HTTP 200), navigate to the OTP
  screen carrying the phone number in grouped format plus the server's `expires_in_seconds` /
  `resend_after_seconds`; on failure, show an error and stay on the SignUp screen (no navigation to
  Login). The request body SHALL carry the full name (`full_name`) and the dharma name (`dharma_name`)
  as separate fields.
- **Verification method:** Unit test (success/failure) + manual QA.
- **Source:** EARS acceptance criterion (submit).

**FR-011 — Phone number format**
- **Priority:** Must
- **Description:** WHEN the form is submitted, THE SYSTEM SHALL send `phone_number` as the grouped,
  dial-code-prefixed display string the user sees (`+84 912 345 678`) — not a digit-only E.164 string.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (phone format).

**FR-012 — Double-submit guard**
- **Priority:** Must
- **Description:** WHEN the user taps submit while a submit request is already in flight, THE SYSTEM
  SHALL ignore the tap and SHALL NOT send the form twice.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (double-submit).

**FR-013 — "I already have an account"**
- **Priority:** Must
- **Description:** WHEN the user taps "Tôi đã có tài khoản", THE SYSTEM SHALL navigate to the Login
  screen.
- **Verification method:** Unit test (nav event).
- **Source:** EARS acceptance criterion (existing account).

**FR-014 — Back**
- **Priority:** Must
- **Description:** WHEN the user taps back, THE SYSTEM SHALL return to Onboarding.
- **Verification method:** Unit test (nav event).
- **Source:** EARS acceptance criterion (back).

**FR-015 — Terms of Service**
- **Priority:** Must
- **Description:** WHEN the user taps "Terms of Service" within the checkbox row text, THE SYSTEM SHALL
  present a screen showing the Terms of Service content, without unchecking or affecting the checkbox
  state.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (ToS).

**FR-016 — Privacy Policy**
- **Priority:** Must
- **Description:** WHEN the user taps "Privacy Policy" within the checkbox row text, THE SYSTEM SHALL
  present a screen showing the Privacy Policy content, without unchecking or affecting the checkbox
  state.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (Privacy Policy).

**FR-017 — Dismiss legal screen**
- **Priority:** Must
- **Description:** WHEN the user dismisses the Terms of Service / Privacy Policy screen, THE SYSTEM SHALL
  return to the SignUp screen with all previously entered field values and checkbox state unchanged.
- **Verification method:** Manual QA.
- **Source:** EARS acceptance criterion (dismiss).

**FR-018 — Legal content source**
- **Priority:** Must
- **Description:** WHEN the Terms of Service / Privacy Policy screen loads, THE SYSTEM SHALL load and
  display the content from a public URL (web page), not a locally-bundled static text or a custom
  backend/CMS API.
- **Verification method:** Code review + manual QA.
- **Source:** EARS acceptance criterion (content source).

**FR-019 — Legal offline state**
- **Priority:** Must
- **Description:** WHEN the device has no internet connection or the URL fails to load, THE SYSTEM SHALL
  show an inline error/retry state on that screen instead of a blank page.
- **Verification method:** Manual QA.
- **Source:** EARS acceptance criterion (offline).

**FR-020 — Full name (required)**
- **Priority:** Must
- **Description:** WHEN the user taps submit and the trimmed full name is empty, THE SYSTEM SHALL show
  "Vui lòng nhập họ và tên" under the field and SHALL NOT call the backend; WHEN the user edits the
  field, THE SYSTEM SHALL clear that error; WHEN the form is submitted, THE SYSTEM SHALL send the trimmed
  value as `full_name`.
  > ⚠️ Not confirmed: the backend's `request-otp` body (strict decoding) does not list `full_name` yet —
  > see `Docs/Assumptions/SignUp/AS-SignUp-004-full-name-sent-as-full-name.md`.
- **Verification method:** Unit test (`ILSignUpViewModelTests`, `ILSignUpRepositoryTests`) + manual QA.
- **Source:** Prototype `isSignup` "Họ và tên"; product owner decision 2026-10-11 (required, `full_name`).

### 3.3 Performance requirements

- **NFR-001 — Submit responsiveness:** the `request-otp` call should complete within a target to be
  confirmed; the 429 lock/cooldown timing must be read from `details`.
  > ⚠️ Not confirmed: the concrete response-time budget — blocks the performance test threshold.

### 3.4 Logical database requirements

- **Client-side:** no local persistence of the form; the `request-otp` call only writes the server's
  `pending_registration`. The follow-on session persistence (Keychain + Core Data) is owned by the OTP
  feature.

### 3.5 Design constraints

- Follow the InnerLamp Design System tokens; reuse the auth components before building new views.
- Follow Clean Architecture: `ILSignUpEntity` (Domain) vs `ILSignUpStateModel` (Presentation); DTO +
  Mapper + Endpoint in Data. No UIKit import in Domain/StateModel.
- The legal screen stays pure Presentation (`WKWebView`, URL parameter) — no Domain layer.

### 3.6 Software system attributes

- **Reliability:** double-submit guard, inline per-field errors, and failure-stays-on-screen.
- **Availability:** the form loads and validates locally; submit degrades to the shared error states.
- **Security:** the password and email are PII handled only in transit (HTTPS); no credentials are
  persisted locally; the `request-otp` endpoint is public (`requiresAuth = false`).
- **Maintainability:** each requirement maps to a unit-testable ViewModel seam; the email regex lives in
  exactly one place (`ILEmailValidator`).
- **Portability:** pure-Domain code is `Foundation`-only.

---

## 4. Verification & traceability

### 4.1 Verification approach

- **Unit tests** (`ILSignUpViewModelTests`, `ILSignUpRepositoryTests`, `ILEmailValidatorTests`) covering
  validation, the real success/failure paths (via `MockILSignUpRepository`), and the error mapping.
- **Manual QA** for the visual layout and the legal screen, plus a real/staging backend run once
  available.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Load state | → spec-writer | TBD |
| FR-002 | Dharma-name suggestion | → spec-writer | TBD |
| FR-003 | Country picker | → spec-writer | TBD |
| FR-004 | Phone hint | → spec-writer | TBD |
| FR-005 | Ordination place | → spec-writer | TBD |
| FR-006 | Email validation | → spec-writer | TBD |
| FR-007 | Password strength | → spec-writer | TBD |
| FR-008 | Terms checkbox | → spec-writer | TBD |
| FR-009 | Submit validation | → spec-writer | TBD |
| FR-010 | Submit | → spec-writer | TBD |
| FR-011 | Phone format | → spec-writer | TBD |
| FR-012 | Double-submit guard | → spec-writer | TBD |
| FR-013 | Existing account | → spec-writer | TBD |
| FR-014 | Back | → spec-writer | TBD |
| FR-015 | ToS | → spec-writer | TBD |
| FR-016 | Privacy Policy | → spec-writer | TBD |
| FR-017 | Dismiss legal | → spec-writer | TBD |
| FR-018 | Legal content source | → spec-writer | TBD |
| FR-019 | Legal offline state | → spec-writer | TBD |
| FR-020 | Full name (required) | `design.md` v1.15 | `ILSignUpViewModelTests` (3), `ILSignUpRepositoryTests` |
| NFR-001 | Submit responsiveness | → spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: the design handoff has no ordination-place field — its final Vietnamese
> label/placeholder/hint and position are unconfirmed — blocks final copy in `vi.json` and a
> design-accurate layout.

> ⚠️ Not confirmed: the backend has not accepted `full_name` on `request-otp` yet (strict body decoding →
> `400 VALIDATION_ERROR` on an unknown key) — blocks a real sign-up; tracked by AS-SignUp-004.

> ⚠️ Not confirmed: the real ToS / Privacy Policy URL strings have not been provided; placeholder/mock
> URLs must not be silently invented in their place.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Pass OTP timing through? | Yes — `ILSignUpOTPEntity` carries `expires_in_seconds` / `resend_after_seconds` | 2026-09-23 |
| Phone number format | Grouped display string; server normalizes to E.164 | 2026-09-23 |
| Route/path | `POST /v1/auth/register/request-otp` (snake_case fields) | 2026-09-22 |
| Phone already registered | Stay on SignUp, show alert (no redirect to Login) | 2026-09-21 |
| "Nơi xuất gia" field | Ordination place, optional | 2026-09-21 |
| Email required? | Yes, required | 2026-09-21 |
| Minimum password length | 8 characters | 2026-09-21 |
| Phone-uniqueness check | Same `request-otp` endpoint (no separate check) | 2026-09-15 |
| Phone validation Vietnam-only? | No — per selected country | 2026-09-21 |
| Dharma name free-text? | Yes, typing is allowed (supersedes 2026-09-15: suggestion list only) — prototype + `ILDharmaNameSuggestionField` | 2026-10-11 |
| Full name required? | Yes, required, sent as `full_name` | 2026-10-11 |
| Ordination place sent as | `ordination_temple_id` (supersedes free-text `ordination_place`, rejected by backend) | 2026-10-11 |
| ToS/Privacy content source | Public URL in a web view | 2026-09-15 |
