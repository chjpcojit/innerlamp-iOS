---
type: Feature
title: Login
description: Returning-user sign-in screen — phone number (country picker) + password, with links to Sign Up, Forgot Password, and guest preview.
resource: InnerLamp/Presentation/Scenes/Login/
tags: [auth, mvvm-c]
status: draft
generated: { by: copilot-cli, at: 2026-09-15T11:34:00+07:00 }
sources:
  - path: InnerLamp/Presentation/Scenes/Login/README.md
    kind: implementation-notes
---

# Summary

Login lets a returning user sign in with a phone number (country/dial-code
picker, same `ILPhoneField` as SignUp) and a password. Tapping "Đăng nhập"
validates both fields locally, then calls `ILLoginUseCase.login`. On
success the flow finishes to the main app (Home — not yet built); on
failure (e.g. invalid credentials) an inline error is shown via
`showError` and the user stays on the screen. There is no email option —
phone number is the only identifier, matching SignUp.

Secondary actions: "Quên?" next to the password field (Forgot Password,
pushed on top of the same stack, not a new coordinator flow yet), a ghost
"Đăng nhập bằng mã SMS" button (not wired — TODO, no `ILOtpCoordinator`
for login yet), a gold-outline "Tạo tài khoản mới" button (→ SignUp), and
a "Xem trước không đăng nhập" text button (not wired — TODO, no guest/Home
flow yet).

**Current limitation**: `login` is not yet wired to a real backend — see
[Pending work](#pending-work) below.

# Architecture

MVVM-C + Clean Architecture, same shape as
[SignUp](/features/signup.md). `ILLoginCoordinator` is owned and wired by
`AppCoordinator` (cross-section navigation to/from Onboarding, SignUp,
Forgot Password).

| Layer | Type | File |
|---|---|---|
| Domain / Entity | Domain Entity | `Domain/Entities/ILLoginEntity.swift` — pure business fields only (`phone`, `password`) |
| Domain / UseCase | UseCase | `Domain/UseCases/Login/ILLoginUseCase.swift` — phone/password validation, `login` (stub) |
| Presentation / State | State Model | `Presentation/Scenes/Login/ILLoginStateModel.swift` — UI-only state, no UIKit import |
| Presentation / ViewModel | ViewModel | `Presentation/Scenes/Login/ILLoginViewModel.swift` — `Input -> Output` per `ViewModelType`, exposes `navigationEventPublisher` |
| Presentation / Coordinator | Coordinator | `Presentation/Scenes/Login/ILLoginCoordinator.swift` |
| Presentation / ViewController | ViewController | `Presentation/Scenes/Login/ILLoginViewController.swift` |

Reuses existing Design System components introduced by SignUp:
`ILPhoneField`, `ILCountryPickerViewController`, `ILCountry`, `ILField`
(with `onTrailingTap` for "Quên?"), `ILTypography.authTitle`,
`ILDividerRow`, `ILButton` (`.primary`, `.ghost`, `.goldOutline`),
`ILLampGlowView`.

# Navigation

```
AppCoordinator
  └─ showLogin() → ILLoginCoordinator
       navigationController.setViewControllers([ILLoginViewController])  // root of its own stack, not pushed
       (tap "Tạo tài khoản mới") → loginDidRequestSignup → AppCoordinator.showSignUp() → finish()
       (tap "Quên?") → loginDidRequestForgotPassword
            → pushed on top of the SAME nav stack (Login stays as root underneath) → coordinator NOT finished here
       (submit succeeds) → loginDidFinishLogin → finish()
            → main app flow (Home — not yet built)
```

# Validation rules

- Phone number: required; valid when the national digit count is `>=`
  the selected country's `nationalDigitCount` (same rule as SignUp,
  generalized per country). Error/valid state only recomputed on submit,
  not per keystroke (field error is cleared immediately on edit instead).
- Password: required, non-empty. No minimum-length/strength check on
  Login (unlike SignUp) — this screen only confirms the credential is
  present before calling the server.
- `phoneE164` is built the same way as SignUp's (`dialCode` + digits
  grouped by 3, space-separated) so it matches the number format stored
  at registration time.

# Pending work

The backend integration is **not yet implemented**. Same status as
SignUp's Phase 3:

- `ILLoginUseCaseImpl.login` is a one-line `print("TODO: ...")` stub — no
  network/Repository call is made, and no local Repository is faked
  either (per the project's "never a guessed real implementation" rule).
- `ILLoginError.invalidCredentials` exists as a type but is never
  actually thrown until a real API responds with that case.
- No `ILLoginDTO` / `ILLoginMapper` / `Endpoint` / `Repository` exist yet
  for this feature — pending the Auth API contract.
- "Đăng nhập bằng mã SMS" (`handleSmsCodeTapped`) and "Xem trước không
  đăng nhập" (`handleGuestPreviewTapped`) are both unwired `TODO`s — no
  OTP-for-login coordinator and no guest/Home flow exist yet.

This concept should be re-verified and have `status` promoted to
`stable` once the Auth API lands and the end-to-end login flow has been
exercised against a real/staging backend.

# Related concepts

- SignUp feature (`InnerLamp/Presentation/Scenes/SignUp/`,
  [features/signup.md](signup.md)) — reachable via "Tạo tài khoản mới";
  shares `ILPhoneField`/`ILCountryPickerViewController` and the
  phone-number formatting rules.
- Forgot Password flow — reachable via "Quên?"; pushed onto the same
  navigation stack as Login. Not yet documented as an OKF concept in
  this bundle.
- OTP feature (`InnerLamp/Presentation/Scenes/Otp/`) — used by SignUp's
  verification flow; a separate OTP-based login ("Đăng nhập bằng mã
  SMS") is referenced but not implemented for this screen yet.
