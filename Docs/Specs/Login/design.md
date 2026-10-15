# Design — Login

Version: 2.1
Last updated: 2026-10-15
Status: in-progress (drift) — phone sign-in, session store, refresh and sign-out built; email sign-in, forgot password, session-ended message and guest prompt planned

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. `Login` and `ForgotPassword` are cross-section scenes
owned by `AppCoordinator`. Session handling is app-wide: `NetworkService` + `AuthSessionRefresher`
(Core), `AppCoordinator` (routing on session end), `ILProfileUseCase.logout` (sign-out).

v2.0 changes:

- **Email replaces phone** on Login; the country picker and the SMS button go.
- **One session store.** Token saving is duplicated today in `ILLoginUseCase` and `ILOtpUseCase`;
  it moves to `ILAuthSessionStore` (save / clear), which sign-in, registration, sign-out, session end
  and password reset all use.
- **Session end is explained and cleaned.** `.authSessionDidExpire` carries the reason; `AppCoordinator`
  runs the full user-scoped cleanup (today only the user row is deleted) and opens Login with the
  message. A guest's `401` is not a session end.
- **New UI:** the session-ended / password-changed banner on Login has no prototype screen; its look is
  agreed with anh Đức before it is built (anh Đức, 2026-10-14: "sẽ cần thêm UI").
- **Forgot password** becomes two views in the `ForgotPassword` scene: request (email) and reset (code +
  new password), reusing the code-timer view of the Otp scene.
- **Guest prompt** is one shared component that account features show instead of their screen.

## Layers & components

| Layer | File | Responsibility | State |
|---|---|---|---|
| Login / Entity | `Domain/Entities/ILLoginEntity.swift` | `email`, `password`. | **change**: `phone` → `email` |
| Login / UseCase | `Domain/UseCases/Login/ILLoginUseCase.swift` | `validateEmail` (non-empty), `validatePassword` (non-empty), `login(_:)` → `ILAuthSessionStore.save`; `ILLoginError`. | **change**: email; drop `invalidPhone`; add `rateLimited(retryAfter:)`; storage via the store |
| Login / Data | `Data/DTOs/ILLoginDTO.swift`, `Data/DataSources/Remote/LoginEndpoint.swift`, `Data/Repositories/ILLoginRepositoryImpl.swift` | Request `{email, password, device}`; device built from `UIDevice` / `Bundle` (`platform: "ios"`); user DTO. | **change**: `email`; user DTO reads `ordination_temple_id` (TD-SignUp-004) |
| Login / State + ViewModel | `Presentation/Scenes/Login/ILLoginStateModel.swift`, `ILLoginViewModel.swift` | Email, password, errors, submitting, `banner` (`.sessionEnded` / `.passwordChanged`), `isRoot`; nav events `.goToSignup`, `.goToForgotPassword(email:)`, `.didLoginSuccessfully`, `.goToGuestPreview`. | **change**: drop phone/country; clear password on failure; banner; drop `.goToOnboarding` |
| Login / ViewController | `Presentation/Scenes/Login/ILLoginViewController.swift` | Email `ILField` (email keyboard, no autocapitalisation), password reveal, "Quên mật khẩu?", banner. | **change**: remove `ILPhoneField`, `handleSmsCodeTapped`, the SMS button and its divider |
| Login / Coordinator | `Presentation/Scenes/Login/ILLoginCoordinator.swift` | `start(banner:prefilledEmail:)`; root with no back when started by `AppCoordinator.showLogin`. | **change** |
| Session store (shared) | new `Domain/Repositories/ILAuthSessionStore.swift` + `Data/Repositories/ILAuthSessionStoreImpl.swift` | `save(_ session: ILAuthSessionEntity)` → Keychain tokens + `ILUserRepository.saveUser`; `clear()` → delete tokens + `ILSessionDataCleaner.clearUserScopedData()` + account-scoped `UserDefaults` keys; keeps device keys. | **planned** — moves code out of `ILLoginUseCase`, `ILOtpUseCase`, `ILProfileUseCase` |
| Refresh | `Core/Networking/AuthSessionRefresher.swift` | Single-flight refresh, rotated pair saved, `.authSessionDidExpire` on refusal. | built; **change**: post only when a refresh token existed (a guest has none — criterion 12) |
| App routing | `App/AppCoordinator.swift` | `handleSessionExpired` → `ILAuthSessionStore.clear()` → `showLogin(banner: .sessionEnded)`; `showLogin(banner:prefilledEmail:)`; `showForgotPassword(email:)`. | **change**: full cleanup (today `deleteUser()` only), banner |
| Sign-out | `Domain/UseCases/Profile/ILProfileUseCase.swift`, `Presentation/Scenes/Profile/Views/ILProfileLogoutButtonView.swift` | Confirm, revoke (result ignored), clear, `onLogout` → Login. | built; **change**: use `ILAuthSessionStore.clear()` |
| Forgot / Entity + UseCase | `Domain/Entities/ILForgotPasswordEntity.swift`, `Domain/UseCases/ForgotPassword/ILForgotPasswordUseCase.swift` | `requestCode(email:) -> ILOtpTimingEntity`, `confirm(email:code:newPassword:)` (validates with `ILSignUpRules`, then on success `ILAuthSessionStore.clear()` if a session is stored); `ILForgotPasswordError`. | **change**: replace the print stub and the phone/email-summary entity |
| Forgot / Data | new `Data/DataSources/Remote/PasswordResetRequestEndpoint.swift`, `PasswordResetConfirmEndpoint.swift`, `Data/DTOs/ILPasswordResetDTO.swift`, `Data/Repositories/ILPasswordResetRepositoryImpl.swift` + `Domain/Repositories/ILPasswordResetRepository.swift` | The two public calls; error mapping. | **planned** |
| Forgot / Request view | `Presentation/Scenes/ForgotPassword/ILForgotPasswordViewController.swift`, `ILForgotPasswordViewModel.swift`, `ILForgotPasswordStateModel.swift` | Email, "Gửi mã", "Trở lại đăng nhập". | **change**: remove phone field, notice, email summary |
| Forgot / Reset view | new `Presentation/Scenes/ForgotPassword/ILResetPasswordViewController.swift`, `ILResetPasswordViewModel.swift`, `ILResetPasswordStateModel.swift` | "Nếu email này có tài khoản, mã đã được gửi", email, code entry, new password (reveal), timers, lock state, "Gửi lại mã". | **planned** |
| Shared code timers | `Presentation/Scenes/Otp/Views/ILOtpResendRowView.swift` → move to `Presentation/Common/Auth/ILCodeTimerView.swift` | Validity countdown + resend wait, used by Otp and Reset. | **change** |
| Forgot / Coordinator | `Presentation/Scenes/ForgotPassword/ILForgotPasswordCoordinator.swift` | Push reset view after request; on confirm success → `AppCoordinator.showLogin(banner: .passwordChanged, prefilledEmail:)`; back → Login. | **change**: drop `forgotPasswordDidRequestOtp` / `…EmailReset` |
| Guest prompt | new `Presentation/Common/Auth/ILSignInPromptView.swift` + `ILAuthGate` (reads `KeychainService.exists(accessTokenKey)`) | Shown by account features for a guest; actions route through `AppCoordinator` to Login / SignUp. | **planned**; each feature wires it in its own spec (Memorial already lists it) |
| Strings | `Resources/Localization/vi.json` (+ `en.json` if present) | `login.field.email.*`, "Email hoặc mật khẩu không đúng", "Quên mật khẩu?", session-ended and password-changed banners, forgot / reset copy, rate-limited; remove phone, SMS and forgot-by-phone keys. | **change** |

## Navigation flow

```
AppCoordinator.showLogin(banner:, prefilledEmail:)   (root, no back)
  ├─ "Đăng nhập" ✓ → showMain()
  ├─ "Quên mật khẩu?" → showForgotPassword(email:)   (pushed)
  │     ├─ "Gửi mã" ✓ → push ILResetPasswordViewController
  │     │     └─ confirm ✓ → showLogin(banner: .passwordChanged, prefilledEmail:)
  │     └─ "Trở lại đăng nhập" → pop
  ├─ "Tạo tài khoản mới" → showSignUp()   (pushed)
  └─ "Vào xem trước, chưa đăng nhập" → showMain()   (guest)

Main (signed in)
  ├─ Me tab "Đăng xuất" → confirm → ILAuthSessionStore.clear() → showLogin()
  └─ refresh refused → .authSessionDidExpire → clear() → showLogin(banner: .sessionEnded)

Main (guest)
  └─ account feature → ILSignInPromptView → showLogin() / showSignUp()
```

## Step-by-step Flow — Session renewal and session end

```
Step 1 — Authenticated call
- Where: NetworkServiceImpl, any requiresAuth endpoint.
- 401 with a stored refresh token → Step 2. 401 with none (guest) → return unauthorized to the caller;
  no notification (criterion 12).

Step 2 — Refresh (single-flight)
- API: POST /v1/auth/refresh {refresh_token}
    - Success → save the rotated pair, retry the original call once.
    - 401 REFRESH_TOKEN_INVALID → Step 3.
    - Offline / timeout / 5xx → keep the session; the original call fails with its transport error.

Step 3 — Session ended
- AuthSessionRefresher clears the tokens and posts .authSessionDidExpire.
- AppCoordinator (main thread): ILAuthSessionStore.clear() (user-scoped Core Data, account-scoped
  UserDefaults) → remove Main → showLogin(banner: .sessionEnded).
```

## Step-by-step Flow — Forgot password

```
Step 1 — Ask for a code
- Trigger: "Gửi mã" with a valid email.
- API: POST /v1/auth/password-reset/request-otp {email}
    - Success → push the reset view with the email and the timing (always the same message).
    - 400 INVALID_EMAIL → error under the field.
    - 429 OTP_RESEND_TOO_SOON / OTP_SEND_LIMITED / OTP_LOCKED / RATE_LIMITED → message with the wait or unlock time.

Step 2 — Resend (repeatable) — Step 1 again after the resend wait; clear the code, restart the timers.

Step 3 — Set the new password
- Pre-condition: 6 digits; new password passes ILSignUpRules (BR-ONB-06).
- API: POST /v1/auth/password-reset/confirm {email, otp_code, new_password}
    - Success → if a session is stored: ILAuthSessionStore.clear() (no logout call — the backend already
      ended every session) → showLogin(banner: .passwordChanged, prefilledEmail: email).
    - 400 OTP_INVALID / OTP_EXPIRED / INVALID_PASSWORD, 429 OTP_LOCKED / RATE_LIMITED → stay, clear the
      new password, show the error; OTP_LOCKED disables the entry until locked_until.
```

## Deliberately stubbed for now

- Email sign-in and `password-reset/*` work only once the backend ships them (innerlamp-be
  `docs/specs/features/login/tasks.md`); until then iOS v2.0 is built and unit-tested against mocks.
