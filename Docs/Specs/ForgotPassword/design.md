# Design — ForgotPassword

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — UI + local validation + navigation done; reset network
call is a stub with no confirmed contract

> See `changelog.md` in this folder for the version history of this spec.

## Overview

ForgotPassword follows MVVM-C + Clean Architecture per `AGENTS.md`, matching
the `Login` / `SignUp` shape. It is a **cross-section navigation** (Login ↔
ForgotPassword ↔ Otp), so `ILForgotPasswordCoordinator` is owned and wired by
`AppCoordinator` (via `showForgotPassword()`). It is **pushed** onto the Login
stack (Login is the root via `setViewControllers`), so the Forgot coordinator
does not `finish()` on the OTP/email-reset transitions — the Forgot VC stays
alive underneath.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILForgotPasswordEntity.swift` | Pure business fields only: `fullPhone`, `fullEmail` (the registered contacts). Also declares `ILForgotPasswordMethod` (`phone`/`email`), which lives in Domain because `sendResetInstructions(method:contact:)` uses it. No UI-only state. |
| Domain / UseCase | `Domain/UseCases/ForgotPassword/ILForgotPasswordUseCase.swift` | `getInitialState()` (returns `ILForgotPasswordEntity.empty` — does **not** read Keychain, per the "no local Repository call" rule), `sendResetInstructions(method:contact:) async throws` — **stub only**. Owns `ILForgotPasswordError` (`.contactNotFound`). |
| Presentation / State | `Presentation/Scenes/ForgotPassword/ILForgotPasswordStateModel.swift` | UI-only state: `method` (default `.phone`), `selectedCountry`, `fullPhone`, `nationalPhone`, `fullEmail`, `submitError`, `isSubmitting`; derived `selectedContact` / `selectedFieldLabel` / `isPhoneValid` / `isSubmitEnabled`. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/ForgotPassword/ILForgotPasswordViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILForgotPasswordNavEvent` (`.goBack`, `.goToOtp(phoneNumber:)`, `.didRequestEmailReset(email:)`) and `navigationEventPublisher`. |
| Presentation / Coordinator | `Presentation/Scenes/ForgotPassword/ILForgotPasswordCoordinator.swift` | `pushViewController`; subscribes `navigationEventPublisher`, forwards to `ILForgotPasswordCoordinatorDelegate` (2 methods). |
| Presentation / ViewController | `Presentation/Scenes/ForgotPassword/ILForgotPasswordViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |

Reused (not owned by ForgotPassword): `ILNavBar`, `ILPhoneField`, `ILButton`,
`ILCountryPickerViewController`. The notice card ("đổi số điện thoại") is a
small inline view built in the VC, not a shared component.

## Navigation flow

```
AppCoordinator
  └─ showForgotPassword() → ILForgotPasswordCoordinator    (owned by AppCoordinator)
       push ILForgotPasswordViewController                  (on top of Login stack)
       (back / "Trở lại đăng nhập") → .goBack             → pop + finish
       (phone reset success)          → .goToOtp(phone)    → showOtp(phone, defaults)
       (email reset success)          → .didRequestEmailReset(email) → (print only)
```

Entry point: `Login` → "Quên?" → `loginDidRequestForgotPassword` →
`showForgotPassword()`.

## Data flow (submit)

1. `ILForgotPasswordViewController` → `submitTappedSubject`.
2. `ILForgotPasswordViewModel.handleSubmit()`:
   - Guard `!isSubmitting && isSubmitEnabled`.
   - `isSubmitting = true`, emit loading state, spawn `Task` calling
     `useCase.sendResetInstructions(method: currentState.method, contact:
     currentState.selectedContact)`.
   - Success → `isSubmitting = false`; emit `.goToOtp(phoneNumber: contact)`
     when `method == .phone`, else `.didRequestEmailReset(email: contact)`.
   - Failure → `isSubmitting = false`, `submitError =
     error.localizedDescription`, emit state → `showError`; **no nav event**.

## Step-by-step Flow — Password reset (ForgotPassword → OTP)

The one-line user story hides a multi-step sequence: the reset instructions
call (this feature) followed by the OTP verification (owned by the OTP
feature). Steps 2–3 belong to `Docs/Specs/Otp/` and are kept here only as a
short cross-reference.

| Step | Route | Owner | Request | Status |
|---|---|---|---|---|
| 1 | reset-instructions (no path confirmed) | ForgotPassword (this feature) | `method` (`phone`/`email`), `contact` | ⚠️ Not confirmed — no endpoint in `Docs/Specs/API/openapi.yaml` v3.9; currently a `print("TODO")` stub |
| 2 | `POST /v1/auth/register/verify-otp` (reused) | OTP feature | `phone_number`, `otp_code` | Implemented, but for `register` purpose — **not** a reset purpose |
| 3 | `POST /v1/auth/resend-otp` (`purpose`) | OTP feature | `phone_number`, `purpose` | `purpose` enum lists `reset_password`, but returns `UNSUPPORTED_OTP_PURPOSE` (US-001 implements only `register`) |

```
Step 1 — Send reset instructions (this feature)
- Trigger: user taps "Gửi hướng dẫn", contact is valid
- Pre-condition: isSubmitEnabled (valid phone for .phone, non-empty email for .email)
- API: (none confirmed) — sendResetInstructions(method:contact:) is a stub
  ⚠️ Not confirmed: the reset-instructions endpoint and whether it is a
  distinct route or a purpose on the existing resend-otp route.
    - Success (stub always succeeds) → Step 2 (phone) or Step 3 (email)
    - Failure (not yet possible) → set submitError, stay, no navigation

Step 2 — Verify OTP (OTP feature, out of this feature's scope)
- Trigger: Step 1 success with method == .phone
- Effect: forgotPasswordDidRequestOtp → AppCoordinator.showOtp(phoneNumber,
  defaultOTPExpirySeconds, defaultResendCooldownSeconds) — reuses the
  post-registration OTP screen. The OTP screen's verify call targets the
  `register` purpose, not a reset purpose, so this is a stopgap, not a true
  reset flow. Full detail owned by Docs/Specs/Otp/design.md.

Step 3 — Email reset (this feature, boundary)
- Trigger: Step 1 success with method == .email
- Effect: .didRequestEmailReset(email:) → AppCoordinator prints a TODO; no
  email-verification screen exists yet.
```

## Deliberately stubbed for now

`ILForgotPasswordUseCaseImpl.sendResetInstructions` is a one-line
`print("TODO: …")` — see `requirements.md` Pending. There is **no**
`ILForgotPasswordRepository` protocol yet (unlike Login, which has one), no
`Data/` implementation, and no DTO/mapper/endpoint. `getInitialState()` also
returns `ILForgotPasswordEntity.empty` rather than reading the registered
contact. Completing this is `tasks.md` Phase 3, and it is blocked on the reset
API contract.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
block `isForgot` (`resetWays`). The phone/email option cards from the design
handoff are **not** present in the shipped UI (see the resolved open question
in `requirements.md`). See `InnerLamp/Presentation/Scenes/ForgotPassword/
README.md` for the full design-vs-implementation comparison and changelog.
