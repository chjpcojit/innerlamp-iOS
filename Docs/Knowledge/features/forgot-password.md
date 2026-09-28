---
type: Feature
title: Forgot Password
description: Password-recovery entry screen — the user submits their registered phone number (or, in the state model only, email) to request reset instructions, then is routed to the OTP screen; the reset call itself is a stub.
resource: InnerLamp/Presentation/Scenes/ForgotPassword/
tags: [auth, mvvm-c]
status: draft
generated: { by: claude-code, at: 2026-09-27T14:54:58+07:00 }
sources:
  - path: Docs/Specs/ForgotPassword/requirements.md
    kind: spec
  - path: Docs/Specs/ForgotPassword/design.md
    kind: spec
  - path: InnerLamp/Domain/UseCases/ForgotPassword/ILForgotPasswordUseCase.swift
    kind: code
  - path: InnerLamp/Domain/Entities/ILForgotPasswordEntity.swift
    kind: code
---

# Summary

ForgotPassword is the entry point for account recovery, reached from Login via
"Quên?". The user enters a contact (a phone number via the shared country-picker
field) and taps "Gửi hướng dẫn". The shipped UI uses the **phone method only**
(the design handoff's phone/email switcher was removed); the StateModel/ViewModel
still support `.email` and its tests cover it, but the live screen never reaches
the email path.

On submit, `sendResetInstructions(method:contact:)` is called and — because it is
a stub — always succeeds, routing a phone reset to the existing OTP screen (a
stopgap: the OTP screen's verify call targets the `register` purpose, not a
reset purpose) or, for email, emitting an event that currently ends in a `print`
in `AppCoordinator`.

**Current limitation**: `sendResetInstructions` is a one-line
`print("TODO: …")` stub and there is no reset API contract — see
[Pending work](#pending-work).

# Architecture

MVVM-C + Clean Architecture, matching Login/SignUp. Cross-section navigation
(Login ↔ ForgotPassword ↔ Otp), so `ILForgotPasswordCoordinator` is owned by
`AppCoordinator` (`showForgotPassword()`) and **pushed** onto the Login stack.

| Layer | Type | File |
|---|---|---|
| Domain / Entity | Domain Entity | `Domain/Entities/ILForgotPasswordEntity.swift` — `fullPhone` / `fullEmail`; also declares `ILForgotPasswordMethod` (`.phone` / `.email`) |
| Domain / UseCase | UseCase | `Domain/UseCases/ForgotPassword/ILForgotPasswordUseCase.swift` — `getInitialState()` (returns `.empty`, no Keychain read), `sendResetInstructions(method:contact:)` **stub**; owns `ILForgotPasswordError` (`.contactNotFound`) |
| Presentation / State | State Model | `Presentation/Scenes/ForgotPassword/ILForgotPasswordStateModel.swift` — UI-only (`method`, `selectedCountry`, `fullPhone`, `nationalPhone`, `fullEmail`, `submitError`, `isSubmitting`; derived `selectedContact` / `isPhoneValid` / `isSubmitEnabled`) |
| Presentation / ViewModel | ViewModel | `Presentation/Scenes/ForgotPassword/ILForgotPasswordViewModel.swift` — `Input -> Output`; owns `ILForgotPasswordNavEvent` (`.goBack`, `.goToOtp(phoneNumber:)`, `.didRequestEmailReset(email:)`) |
| Presentation / Coordinator | Coordinator | `Presentation/Scenes/ForgotPassword/ILForgotPasswordCoordinator.swift` — `pushViewController`, forwards to `ILForgotPasswordCoordinatorDelegate` |
| Presentation / ViewController | ViewController | `Presentation/Scenes/ForgotPassword/ILForgotPasswordViewController.swift` |
| Tests | Unit tests | `InnerLampTests/ILForgotPasswordViewModelTests.swift` (11 tests) |

Reuses `ILNavBar`, `ILPhoneField`, `ILButton`, `ILCountryPickerViewController`.
There is **no** `ILForgotPasswordRepository` protocol and no Data layer — unlike
Login (which has a protocol but no impl), this feature has neither.

# Navigation

```
AppCoordinator
  └─ showForgotPassword() → ILForgotPasswordCoordinator     (owned by AppCoordinator)
       push ILForgotPasswordViewController                   (on top of the Login stack)
       (back / "Trở lại đăng nhập") → .goBack              → pop + finish
       (phone reset success)         → .goToOtp(phone)     → showOtp(phone, defaults)
       (email reset success)         → .didRequestEmailReset(email) → (print only)
```

Entry point: `Login` → "Quên?" → `loginDidRequestForgotPassword` →
`showForgotPassword()`.

# Validation rules

Validation is synchronous and runs on submit (not per keystroke), using the same
country-aware phone rule as Login/SignUp:

- Phone (`.phone` method): valid when the national digit count meets the selected
  country's `nationalDigitRange`; `isSubmitEnabled` gates the CTA.
- Email (`.email` method, unreachable in the shipped UI): non-empty.
- A second submit while `isSubmitting` is ignored (no double submit).

The submit CTA stays disabled until a valid contact is entered.

# Pending work

- **`sendResetInstructions` is a stub** (`ILForgotPasswordUseCaseImpl`,
  `print("TODO: …")`), so the submit button always succeeds at runtime. There is
  no `ILForgotPasswordRepository`, DTO, mapper, or Endpoint.
  > ⚠️ Not confirmed: the reset-instructions contract — no reset endpoint exists
  > in `Docs/Specs/API/openapi.yaml` v3.9. Blocks `tasks.md` Phase 3.
- The phone reset path reuses the post-registration OTP screen as a stopgap
  (`AppCoordinator.forgotPasswordDidRequestOtp` passes the default 90s/60s
  timing); the OTP verify call targets the `register` purpose, not a reset
  purpose. A true reset OTP flow is a separate scope.
- `.didRequestEmailReset` reaches a `print` in `AppCoordinator` — no
  email-verification screen exists.
- `getInitialState()` returns an empty entity (no pre-fill of the registered
  contact); whether to pre-fill is unconfirmed.
- Promote to `stable` once the reset API lands and the flow is exercised
  end-to-end.

# Known gaps vs. design

- The design handoff's `isForgot` block (`resetWays`) has two option cards
  (phone/email); the shipped UI removed the switcher and always uses phone.
  `methodChanged` is bound to `Empty`; the `.email` support survives only in the
  StateModel/ViewModel and tests.

# Related concepts

- [Login](login.md) (`InnerLamp/Presentation/Scenes/Login/`) — reachable via
  "Quên?"; this screen is pushed on top of Login's stack.
- [OTP Verification](otp.md) (`InnerLamp/Presentation/Scenes/Otp/`) — the phone
  reset path reuses this screen (stopgap), with default timing.
- [Sign Up](signup.md) (`InnerLamp/Presentation/Scenes/SignUp/`) — shares the
  country-aware phone validation rule and `ILPhoneField`.
