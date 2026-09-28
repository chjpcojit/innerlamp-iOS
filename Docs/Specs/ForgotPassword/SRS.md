# Software Requirements Specification — ForgotPassword

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | ForgotPassword |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-09-27 |
| Status | retroactive — reconstructed from `requirements.md` / `design.md` / `tasks.md` |
| Owner / author | il-ba (Business Analyst) |
| Downstream handoff | `il-spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

This document is the Software Requirements Specification for the **ForgotPassword** feature of
InnerLamp. It defines — for the PM and engineering — *what* the feature must do, at business level, in
IEEE 29148-2018 form. It is reconstructed retroactively from the already-implemented feature and its
engineering spec.

### 1.2 Scope

**In scope:**

- A screen where a user who forgot their password can request reset instructions for their registered
  contact (phone, by default; email supported by the state model but not by the shipped UI).
- Phone entry with the shared country picker, live validity feedback, and a submit CTA.
- Navigation to the existing OTP screen (phone path) or an email-reset event (email path).

**Out of scope:**

- Password-reset verification itself (OTP entry, and any "choose a new password" step) — owned by the
  OTP feature / a future reset flow.
- Email-based reset verification — there is no email-verification screen yet (the event currently
  reaches a `print` in `AppCoordinator`).

### 1.3 Product overview

InnerLamp is a Buddhist companion app (UIKit, Swift, Clean Architecture + MVVM-C). ForgotPassword is a
**cross-section navigation** (Login ↔ ForgotPassword ↔ Otp) that lets a user who forgot their password
request reset instructions before verifying ownership via OTP.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Reset contact | The registered phone number or email address used to receive reset instructions. |
| Reset method | `ILForgotPasswordMethod` — `.phone` (default) or `.email`. |
| Dial code / national number | The country dial code (e.g. `+84`) and the national digits, combined into the full phone value. |

### 1.5 References

- `Docs/Specs/ForgotPassword/requirements.md`, `design.md`, `tasks.md`, `changelog.md`.
- `Docs/Specs/Otp/` — the OTP screen the phone path reuses.
- `Docs/Specs/API/openapi.yaml` (v3.9) — has **no** forgot-password/reset endpoint.
- `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`, block `isForgot`.

### 1.6 Document organization

§2 describes the feature at a product level. §3 gives the functional (`FR-*`) and non-functional
(`NFR-*`) requirements. §4 defines verification and the traceability matrix. §5 lists open questions.

---

## 2. Overall description

### 2.1 Product perspective

This is a **new feature** within InnerLamp, following the `Login` / `SignUp` shape. It is a
cross-section navigation owned by `AppCoordinator` (via `showForgotPassword()`), pushed onto the Login
stack. The only external system it *would* touch is a **reset-instructions backend endpoint**, which
does not yet exist in the API contract.

### 2.2 Product functions

- Show the ForgotPassword screen with an empty phone field and a disabled submit CTA (`FR-001`).
- Let the user pick a country and enter a phone number with live validity (`FR-002`, `FR-003`).
- Send reset instructions and route on success (`FR-004`).
- Guard against double submission and support back navigation (`FR-005`, `FR-006`).
- Select the reset contact by method (`FR-007`).

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| User who forgot their password | A registered user trying to regain access. | Requests reset instructions for their registered contact; does not need to be signed in. |

### 2.4 Operating environment

- Platform: iOS, minimum version per the existing project target.
- Devices: iPhone (primary).
- Network: the submit path is intended to require network (the real call is currently a stub); the
  screen itself loads and validates locally.

### 2.5 Design and implementation constraints

- Swift + UIKit (100% programmatic UI), Clean Architecture + MVVM-C + Coordinator, per `AGENTS.md`.
- Manual DI via `DIContainer`; the coordinator is owned by `AppCoordinator`.
- No hardcoded user-facing text — strings come from the JSON localization system (`"forgotPassword.*"`
  keys); no inline font sizes or colors — use `ILTypography`, `ILColors`, `ILMetrics`, and existing
  components (`ILNavBar`, `ILPhoneField`, `ILButton`, `ILCountryPickerViewController`).
- No UIKit import in ViewModels/Domain.

### 2.6 User documentation

**N/A** — this is a consumer app feature; no separate manual is produced.

### 2.7 Assumptions and dependencies

- **Assumptions:**
  - A reset-instructions endpoint will exist (distinct route or a `purpose` on the existing
    `resend-otp` route).
  - The phone path reuses the existing OTP screen as a stopgap until a true reset flow exists.
- **Dependencies:**
  - `Docs/Specs/Otp/` — the OTP screen the phone path navigates to.
  - The backend reset API — **not yet confirmed** (blocks the Data layer).
  - A future Auth API if the registered contact is to be pre-filled.

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

A single screen: title/subtitle, a phone field (country flag + dial code + national number), the shared
country picker, a notice card, a submit CTA ("Gửi hướng dẫn" — "Send instructions"), and a "Trở lại
đăng nhập" ("Back to login") link. The phone/email method switcher from the design handoff is
deliberately **omitted** in the shipped UI (phone-only).

#### 3.1.2 Hardware interfaces

**N/A** — this is an iOS application feature with no custom hardware interface.

#### 3.1.3 Software interfaces

The reset-instructions endpoint does **not** exist in `Docs/Specs/API/openapi.yaml` v3.9 (the only auth
paths are `register/request-otp`, `register/verify-otp`, `resend-otp`, `login`, `refresh`, `logout`).

> ⚠️ Not confirmed: the forgot-password API contract — whether it is a distinct route or a `purpose` on
> the existing `resend-otp` route, and its request/response/error shapes — blocks the Data layer
> (Repository, DTO, Mapper, Endpoint).

#### 3.1.4 Communication interfaces

- HTTPS + JSON through the shared `ApiResponse` envelope and `NetworkService` (once the endpoint exists).

### 3.2 Functional requirements

**FR-001 — Load state**
- **Priority:** Must
- **Description:** WHEN the screen loads, THE SYSTEM SHALL show a title/subtitle and an empty phone
  field (default country selected); the submit button SHALL be disabled until a valid contact is entered.
- **Verification method:** Unit test (ViewModel) + manual QA.
- **Source:** EARS acceptance criterion (load state).

**FR-002 — Country picker**
- **Priority:** Must
- **Description:** WHEN the user taps the country flag/dial code, THE SYSTEM SHALL present the shared
  country picker (search + list of 12 countries); selecting a country SHALL update the dial code while
  preserving the already-typed national number.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (country picker).

**FR-003 — Phone entry and validity**
- **Priority:** Must
- **Description:** WHEN the user types a phone number, THE SYSTEM SHALL rebuild the full phone value
  from the selected dial code + typed digits, show a validity tick when the digit count meets the
  country's minimum, and enable the submit button.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (phone entry/validity).

**FR-004 — Submit reset instructions**
- **Priority:** Must
- **Description:** WHEN the user taps "Gửi hướng dẫn" with a valid contact, THE SYSTEM SHALL show a
  loading state and call the reset-instructions use case, then: on success with the phone method,
  navigate to the OTP screen carrying the phone number; on success with the email method, emit an
  email-reset event; on failure, show the returned error and stay on the screen with no navigation
  event.
- **Verification method:** Unit test (nav events + failure) + manual QA.
- **Source:** EARS acceptance criterion (submit success/failure).

**FR-005 — Double-submit guard**
- **Priority:** Must
- **Description:** WHEN a reset request is already in flight, THE SYSTEM SHALL ignore a second tap on
  the submit button and SHALL NOT submit twice.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (double-submit).

**FR-006 — Back navigation**
- **Priority:** Must
- **Description:** WHEN the user taps the back control or "Trở lại đăng nhập", THE SYSTEM SHALL return
  to the Login screen.
- **Verification method:** Unit test (nav event).
- **Source:** EARS acceptance criterion (back).

**FR-007 — Method-specific contact**
- **Priority:** Should
- **Description:** WHEN the phone method is selected, THE SYSTEM SHALL use the phone number as the reset
  contact; WHEN the email method is selected, THE SYSTEM SHALL use the email address as the reset
  contact.
- **Verification method:** Unit test (method change).
- **Source:** EARS acceptance criterion (method selection).

### 3.3 Performance requirements

- **NFR-001 — Submit responsiveness:** the reset-instructions call should complete within a target to be
  confirmed once the backend contract exists.
  > ⚠️ Not confirmed: the concrete response-time budget — blocks the performance test threshold.

### 3.4 Logical database requirements

- **Client-side:** no local persistence is required for this feature (the registered contact is typed
  manually; see the pre-fill open question in §5).

### 3.5 Design constraints

- Follow the InnerLamp Design System tokens and reuse the existing auth components before building new
  views.
- Follow Clean Architecture: `ILForgotPasswordEntity` (pure business fields, Domain) vs
  `ILForgotPasswordStateModel` (UI-only state, Presentation). No UIKit import in Domain/StateModel.

### 3.6 Software system attributes

- **Reliability:** double-submit guard and failure-stays-on-screen behavior; no crash on missing contact.
- **Availability:** the screen loads and validates locally; the submit path degrades to an error state
  until the backend exists.
- **Security:** the screen collects a phone number / email (PII); it is not logged or persisted locally,
  and traffic will be HTTPS once the endpoint exists.
- **Maintainability:** each requirement maps to a unit-testable ViewModel seam.
- **Portability:** pure-Domain code is `Foundation`-only.

---

## 4. Verification & traceability

### 4.1 Verification approach

- **Unit tests** (`XCTest`) for the ViewModel via `MockILForgotPasswordUseCase`: initial state, method
  change, phone/country change, back events, submit-without-contact no-op, phone→OTP, email→reset, and
  failure-stays-on-screen.
- **Manual QA** for the visual layout and the country picker interaction.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Load state | → il-spec-writer | TBD |
| FR-002 | Country picker | → il-spec-writer | TBD |
| FR-003 | Phone entry/validity | → il-spec-writer | TBD |
| FR-004 | Submit reset | → il-spec-writer | TBD |
| FR-005 | Double-submit guard | → il-spec-writer | TBD |
| FR-006 | Back navigation | → il-spec-writer | TBD |
| FR-007 | Method-specific contact | → il-spec-writer | TBD |
| NFR-001 | Submit responsiveness | → il-spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: the forgot-password API contract — no reset endpoint exists in
> `Docs/Specs/API/openapi.yaml` v3.9, and it is unclear whether reset is a distinct route or a `purpose`
> on `resend-otp` (the `ResendOTPRequest.purpose` enum lists `reset_password` but is documented as
> returning `UNSUPPORTED_OTP_PURPOSE`) — blocks the Data layer.

> ⚠️ Not confirmed: whether the app should pre-fill the registered phone number/email from a future Auth
> API, or keep requiring manual entry — affects whether `getInitialState()` stays empty.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Phone/email switcher in the UI | No — shipped UI is phone-only; the state model still supports `.email` | 2026-09-27 |
| Phone path reuse the OTP screen | Yes, as a stopgap (post-registration OTP, default timing) | 2026-09-27 |
