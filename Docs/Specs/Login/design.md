# Design — Login

Version: 1.1
Last updated: 2026-09-27
Status: in-progress — UI + local validation + navigation done; login contract
confirmed (`POST /v1/auth/login`), Data layer not yet implemented

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Login follows MVVM-C + Clean Architecture per `AGENTS.md`, matching the
canonical `Onboarding` / `SignUp` feature shape. It is a **cross-section
navigation** (Onboarding ↔ SignUp ↔ ForgotPassword ↔ Main), so
`ILLoginCoordinator` is owned and wired by `AppCoordinator` (via
`showLogin()`), not by a parent feature coordinator. Unlike SignUp (which is
pushed onto the Onboarding stack), Login is set as the **root of its own
stack** with `setViewControllers`, so "Tạo tài khoản mới" pushes SignUp on top
of Login rather than replacing it.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILLoginEntity.swift` | Pure business fields only: `phone` (E.164 grouped display string), `password`. No UI-only state. |
| Domain / Entity (shared) | `Domain/Entities/ILAuthSessionEntity.swift` | Return type of `ILLoginRepository.login`: `accessToken`, `refreshToken`, `user`. Shared with Otp/SignUp; not Login-specific. |
| Domain / UseCase | `Domain/UseCases/Login/ILLoginUseCase.swift` | `getInitialState()`, `validatePhone(nationalDigits:country:)`, `validatePassword(_:)` (non-empty only), and `login(_ credential: ILLoginEntity) async throws` — **stub only** (see "Deliberately stubbed for now"). Also owns `ILLoginError` (`.invalidCredentials`). |
| Domain / Repository | `Domain/Repositories/ILLoginRepository.swift` | Entity in / Entity out: `login(_ entity: ILLoginEntity) async throws -> ILAuthSessionEntity`. **No Data-layer implementation exists yet.** |
| Presentation / State | `Presentation/Scenes/Login/ILLoginStateModel.swift` | UI-only state: `selectedCountry`, `phone`, `password`, field errors, `submitError`, `isSubmitting`; derived `nationalDigits` / `isPhoneValid` / `phoneE164` (grouped display string, same rule as `ILSignUpStateModel.phoneE164`). No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Login/ILLoginViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILLoginNavEvent` (`.goToOnboarding`, `.goToSignup`, `.goToForgotPassword`, `.didLoginSuccessfully`, `.goToGuestPreview`) and `navigationEventPublisher`. |
| Presentation / Coordinator | `Presentation/Scenes/Login/ILLoginCoordinator.swift` | `setViewControllers([ILLoginViewController])`; subscribes `navigationEventPublisher`, forwards to `ILLoginCoordinatorDelegate` (5 methods). |
| Presentation / ViewController | `Presentation/Scenes/Login/ILLoginViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`; `TransitionProviding` → `CrossFadeTransition`. |
| Shared Design System component | `Presentation/Common/DesignSystem/Components/ILDividerRow.swift` | Generic "or" divider row (two rules + centered label). Added for Login's footer, reused across auth screens. |

Reused (not owned by Login): `ILNavBar`, `ILPhoneField`, `ILField`,
`ILButton`, `ILLampGlowView`, `ILCountryPickerViewController` — all generic,
already added by SignUp.

## Navigation flow

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

Entry points into Login:
- `Onboarding` → "Đã có tài khoản" → `onboardingDidRequestLogin`
- `SignUp` → "Tôi đã có tài khoản" → `signUpDidRequestLogin`

## Data flow (submit)

1. `ILLoginViewController.handleSubmitTapped()` → `submitTappedSubject`.
2. `ILLoginViewModel.handleSubmit()`:
   - Guard `!isSubmitting` (blocks double-tap).
   - Validate `phone` (country-aware) and `password` (non-empty only)
     synchronously via `useCase.validateXxx`.
   - On validation error → emit state with per-field errors, stop.
   - On valid → `isSubmitting = true`, emit loading state, spawn `Task`
     calling `useCase.login(ILLoginEntity(phone: currentState.phoneE164,
     password: currentState.password))`.
   - Success → `isSubmitting = false`, emit state, emit
     `.didLoginSuccessfully`.
   - Failure → `isSubmitting = false`, `submitError =
     error.localizedDescription`, emit state → `showError` alert; **no nav
     event**, stay on screen.

## Deliberately stubbed for now

`ILLoginUseCaseImpl.login` is a one-line `print("TODO: …")` — see
`requirements.md` Pending. `ILLoginRepository` exists as a Domain protocol
(`login → ILAuthSessionEntity`), but:

- There is **no `ILLoginRepositoryImpl`** under `Data/Repositories/`.
- `ILLoginUseCaseImpl.init()` injects nothing (the README notes the real
  `NetworkService`/repository must be injected when the call is implemented).
- No `ILLoginDTO`, mapper, or `LoginEndpoint` exists.

This is intentional per the project's "never a guessed real implementation"
rule (see `ui-builder`'s `references/data_layer_boundaries.md`). The
stub means the submit button always reports success at runtime. Completing
this is `tasks.md` Phase 3.

## Login API contract (confirmed)

The login endpoint is confirmed in `Docs/Specs/API/openapi.yaml` v3.9 — this
is **not** an open question; only the Data-layer implementation is pending.

| Route | Request | Success data | Confirmed failures |
|---|---|---|---|
| `POST /v1/auth/login` | `LoginRequest` = `phone_number` (any `IsValidPhone` shape, normalized to E.164 server-side), `password` (non-empty only), `device` {platform, device_model, os_version?, app_version?, device_name?} | `VerifyOTPData` = `access_token`, `refresh_token` (stored SHA-256), `user` | `400` VALIDATION_ERROR / INVALID_PHONE / INVALID_PASSWORD / INVALID_DEVICE (none count as a failed attempt), `401` INVALID_CREDENTIALS (wrong password / unknown number / number only in pending_registration all collapse here; 5 consecutive failures lock the number 15 min — the fifth still answers 401, the next answers 429 even with the correct password), `413` PAYLOAD_TOO_LARGE, `429` LOGIN_LOCKED (`details.locked_until`), `500` INTERNAL_ERROR |

Public (`requiresAuth = false`). Success returns the standard `ApiResponse`
envelope (`{"success": true, "data": …}`), handled centrally by
`NetworkService` (see `Docs/Specs/Networking/design.md`).

Two gaps in the current Domain layer the Data layer must close when it lands:

1. **`ILLoginEntity` lacks `device`.** The entity has only `phone`/`password`;
   the contract requires a `device` object (at minimum `platform` +
   `device_model`). Either the entity gains a `device` field, or the repository
   derives it from `UIDevice`/bundle info at the Data boundary (the latter
   keeps Device details out of Domain).
2. **`ILLoginError` is incomplete.** It has only `.invalidCredentials`; the
   mapped failures above need cases, and the 429 lock timing must be read from
   `details.locked_until` (mirroring `ILSignUpError`'s use of
   `ILUnlockTimeFormatter`).

## SMS-code login (not implemented)

`ILLoginViewController.handleSmsCodeTapped()` is an empty TODO. The design
handoff's `isLogin` block includes a "Đăng nhập bằng mã SMS" CTA, but there is
no OTP-for-login flow. The existing OTP feature (`Docs/Specs/Otp/`) only serves
post-registration `verify-otp` / `resend-otp`; wiring it for login is a
separate scope (`tasks.md` Phase 4).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
block `isLogin`. See `InnerLamp/Presentation/Scenes/Login/README.md` for the
full design-vs-implementation comparison and changelog.
