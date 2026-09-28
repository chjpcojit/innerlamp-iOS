---
type: Feature
title: Login
description: Returning-user sign-in screen — phone number (country picker) + password, with links to Sign Up, Forgot Password, and guest preview; the login call itself is a stub pending the Data layer.
resource: InnerLamp/Presentation/Scenes/Login/
tags: [auth, mvvm-c]
status: draft
generated: { by: claude-code, at: 2026-09-27T14:54:58+07:00 }
sources:
  - path: Docs/Specs/Login/requirements.md
    kind: spec
  - path: Docs/Specs/Login/design.md
    kind: spec
  - path: InnerLamp/Domain/UseCases/Login/ILLoginUseCase.swift
    kind: code
  - path: InnerLamp/Domain/Repositories/ILLoginRepository.swift
    kind: code
  - path: InnerLamp/Presentation/Scenes/Login/ILLoginCoordinator.swift
    kind: code
---

# Summary

Login lets a returning user sign in with a phone number (country/dial-code
picker, same `ILPhoneField` as SignUp) and a password. Tapping "Đăng nhập"
validates both fields synchronously, then calls `ILLoginUseCase.login`. On
success the flow finishes to the main app (the `ILMainTabCoordinator` shell); on
failure an inline error is shown and the user stays on the screen. There is no
email option — phone is the only identifier.

Secondary actions: "Quên?" (→ ForgotPassword, a real coordinator pushed on top
of the same stack), "Tạo tài khoản mới" (→ SignUp), "Đăng nhập bằng mã SMS"
(renders but `handleSmsCodeTapped()` is an empty TODO — no OTP-for-login flow),
and "Xem trước, đăng nhập sau" (→ guest preview → `showMain()`).

**Current limitation**: `login` is a one-line `print("TODO: …")` stub — the
contract is confirmed but the Data layer is not built — see
[Pending work](#pending-work).

# Architecture

MVVM-C + Clean Architecture, same shape as SignUp. `ILLoginCoordinator` is owned
and wired by `AppCoordinator` (`showLogin()`) and set as the **root of its own
stack** via `setViewControllers` (so SignUp/ForgotPassword are pushed on top of
it, not replacing it).

| Layer | Type | File |
|---|---|---|
| Domain / Entity | Domain Entity | `Domain/Entities/ILLoginEntity.swift` — pure fields `phone` (grouped E.164 display string), `password` |
| Domain / Entity (shared) | Domain Entity | `Domain/Entities/ILAuthSessionEntity.swift` — `accessToken` / `refreshToken` / `user`; the `ILLoginRepository.login` return type, shared with Otp |
| Domain / UseCase | UseCase | `Domain/UseCases/Login/ILLoginUseCase.swift` — `getInitialState()`, `validatePhone(nationalDigits:country:)`, `validatePassword(_:)` (non-empty only), `login(_:)` **stub**; owns `ILLoginError` (`.invalidCredentials`) |
| Domain / Repository | Repository protocol | `Domain/Repositories/ILLoginRepository.swift` — `login(_ entity:) async throws -> ILAuthSessionEntity`; **no Data-layer impl yet** |
| Presentation / State | State Model | `Presentation/Scenes/Login/ILLoginStateModel.swift` — UI-only (`selectedCountry`, `phone`, `password`, field errors, `submitError`, `isSubmitting`; derived `nationalDigits` / `isPhoneValid` / `phoneE164`) |
| Presentation / ViewModel | ViewModel | `Presentation/Scenes/Login/ILLoginViewModel.swift` — `Input -> Output`; owns `ILLoginNavEvent` (`.goToOnboarding`, `.goToSignup`, `.goToForgotPassword`, `.didLoginSuccessfully`, `.goToGuestPreview`) |
| Presentation / Coordinator | Coordinator | `Presentation/Scenes/Login/ILLoginCoordinator.swift` — `setViewControllers([ILLoginViewController])`; forwards to `ILLoginCoordinatorDelegate` (5 methods) |
| Presentation / ViewController | ViewController | `Presentation/Scenes/Login/ILLoginViewController.swift` |
| Tests | Unit tests | `InnerLampTests/ILLoginViewModelTests.swift` (9 tests) |

Reuses SignUp's Design System components (`ILPhoneField`,
`ILCountryPickerViewController`, `ILField` with `onTrailingTap` for "Quên?",
`ILButton`, `ILLampGlowView`, `ILTypography.authTitle`). Introduced `ILDividerRow`
(a generic footer divider).

# Navigation

```
AppCoordinator
  ├─ showLogin() → ILLoginCoordinator            (owned by AppCoordinator)
  │    setViewControllers([ILLoginViewController])   ← root of its own stack
  │    (back)                → .goToOnboarding      → showOnboarding()   [finish]
  │    ("Tạo tài khoản mới") → .goToSignup          → showSignUp()       [no finish — pushed]
  │    ("Quên?")             → .goToForgotPassword  → showForgotPassword() [no finish — pushed]
  │    (login success)       → .didLoginSuccessfully → showMain()         [finish]
  │    ("Xem trước...")      → .goToGuestPreview    → showMain()         [finish]
```

Entry points: Onboarding ("Đã có tài khoản") and SignUp ("Tôi đã có tài khoản").

# Validation rules

Validation runs once on submit (not per keystroke); field errors are cleared when
the user edits the offending field.

- Phone: required; valid when the national digit count meets the selected
  country's `nationalDigitRange` (same country-aware rule as SignUp).
- Password: required, non-empty only — no minimum length or strength check (the
  length floor is a registration rule; the server is the authority on
  credentials).
- `phoneE164` is built the same grouped, dial-code-prefixed way as SignUp so it
  matches the stored format.

# Submit flow

`handleSubmit()` guards `!isSubmitting`, validates synchronously, then calls
`useCase.login(ILLoginEntity(phone: currentState.phoneE164, password: ...))`.
On success it emits `.didLoginSuccessfully`; on failure `submitError` is set and
the user stays on the screen (no navigation event).

# Pending work

The backend integration is **not yet implemented** — only the contract is
confirmed (`Docs/Specs/API/openapi.yaml` v3.9, `POST /v1/auth/login`):

- `ILLoginUseCaseImpl.login` is a one-line `print("TODO: …")` stub; the submit
  button always succeeds at runtime.
- `ILLoginRepository` exists as a Domain protocol but there is no
  `ILLoginRepositoryImpl`, no `ILLoginDTO` / mapper, and no `LoginEndpoint`.
- Two Domain gaps the Data layer must close:
  1. `ILLoginEntity` has only `phone`/`password`; the contract requires a
     `device` object (`platform` + `device_model`).
  2. `ILLoginError` has only `.invalidCredentials`; the contract's mapped
     failures (`INVALID_PHONE` / `INVALID_PASSWORD` / `INVALID_DEVICE` /
     `INVALID_CREDENTIALS` / `LOGIN_LOCKED` with `details.locked_until` /
     `PAYLOAD_TOO_LARGE` / `INTERNAL_ERROR` + transport) need cases.
- "Đăng nhập bằng mã SMS" (`handleSmsCodeTapped`) is an unwired TODO — no
  OTP-for-login flow.
  > ⚠️ Not confirmed: whether SMS login reuses the OTP feature (the
  > `ResendOTPRequest.purpose` enum lists `login`, but US-001 only implements
  > `register`).
- Promote to `stable` once the login Data layer lands and the end-to-end flow is
  exercised against a real/staging backend.

# Related concepts

- [Sign Up](signup.md) (`InnerLamp/Presentation/Scenes/SignUp/`) — reachable via
  "Tạo tài khoản mới"; shares `ILPhoneField` / `ILCountryPickerViewController`
  and the phone-number formatting rules.
- [Forgot Password](forgot-password.md)
  (`InnerLamp/Presentation/Scenes/ForgotPassword/`) — reachable via "Quên?";
  pushed onto the same stack.
- [OTP Verification](otp.md) (`InnerLamp/Presentation/Scenes/Otp/`) — the "Đăng
  nhập bằng mã SMS" flow would reuse it; not wired yet.
- [Onboarding](onboarding.md) (`InnerLamp/Presentation/Scenes/Onboarding/`) — the
  back-control destination.
- [Main](main.md) (`InnerLamp/Presentation/Scenes/Main/`) — the success and guest
  destinations (`showMain()`).
