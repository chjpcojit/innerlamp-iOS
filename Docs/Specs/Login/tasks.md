# Tasks — Login

Version: 2.1
Last updated: 2026-10-15
Status: in-progress (drift) — Phase 1–7 not started for v2.0; items marked `[x]` were read in code on 2026-10-14 and still match

> See `changelog.md` in this folder for the version history of this spec.

Every item traces to a row of `design.md` "Layers & components" or a step of its Step-by-step Flows.

## Phase 1 — Session store

- [ ] `ILAuthSessionStore` + `ILAuthSessionStoreImpl` (`save`, `clear`); move token saving out of `ILLoginUseCase` and `ILOtpUseCase`, clearing out of `ILProfileUseCase.logout` (criteria 8, 13)
- [x] Tokens only in the Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (`KeychainService`) (criterion 8)
- [x] Launch with a stored session opens Main (`ILSplashUseCase.hasSession`) (criterion 9)
- [ ] Unit tests: `clear()` removes tokens, user-scoped Core Data and account-scoped defaults, keeps `has_completed_onboarding` and the intro choices

## Phase 2 — Email sign-in

- [ ] `ILLoginEntity.email`; `ILLoginDTO` / `ILLoginRepositoryImpl`: `{email, password, device}`, user DTO `ordination_temple_id` (criterion 3)
- [ ] `ILLoginUseCase`: email non-empty, password non-empty; errors per Error → UI incl. `RATE_LIMITED` (criteria 2, 4, 22)
- [ ] `ILLoginStateModel` / `ILLoginViewModel` / `ILLoginViewController`: email field, remove phone + country picker + SMS button, "Quên mật khẩu?", clear password on failure, banner, root without back (criteria 1, 3, 7)
- [x] Device object `platform: "ios"`, model, OS and app version (`ILLoginRepositoryImpl`) (criterion 3)
- [x] Lock message with the unlock time from `locked_until` (`ILLoginError.loginLocked`, `ILUnlockTimeFormatter`) (criterion 5)
- [x] Second tap ignored while signing in (`ILLoginViewModel.handleSubmit`) (criterion 6)
- [ ] Unit tests: request body, each error, password cleared, banner shown from the coordinator argument

## Phase 3 — Session end

- [x] Single-flight refresh, rotated pair saved, offline / 5xx keeps the session (`AuthSessionRefresher`) (criterion 10)
- [ ] `AuthSessionRefresher`: post `.authSessionDidExpire` only when a refresh token existed (criterion 12)
- [ ] `AppCoordinator.handleSessionExpired`: `ILAuthSessionStore.clear()` (not only `deleteUser()`), `showLogin(banner: .sessionEnded)` (criterion 11)
- [ ] UI for the "Phiên đăng nhập đã hết" and "Đã đổi mật khẩu" banner on Login — not in the design prototype; agree the look with anh Đức before building (criteria 11, 17)
- [ ] Unit tests: refusal → full cleanup + banner; guest 401 → no notification

## Phase 4 — Sign-out

- [x] Confirmation, revoke with the result ignored, works offline, opens Login (`ILProfileUseCase.logout`, `ILProfileLogoutButtonView`, `AppCoordinator.handleLoggedOut`) (criterion 13)
- [ ] Switch to `ILAuthSessionStore.clear()` (Phase 1)

## Phase 5 — Forgot password

- [ ] `ILPasswordResetRepository` + impl, `PasswordResetRequestEndpoint`, `PasswordResetConfirmEndpoint`, `ILPasswordResetDTO` (Step 1, Step 3)
- [ ] `ILForgotPasswordUseCase`: `requestCode`, `confirm` (checks with `ILSignUpRules`, clears a stored session on success); replace the print stub and `ILForgotPasswordEntity` (criteria 15, 17)
- [ ] Request view: email field pre-filled, "Gửi mã", "Trở lại đăng nhập"; remove phone field, notice and email summary (criterion 14)
- [ ] `ILResetPasswordViewController` / ViewModel / StateModel: message, code, new password, timers, lock, resend (criteria 15, 16, 18)
- [ ] Move `ILOtpResendRowView` to `Presentation/Common/Auth/ILCodeTimerView` and use it in Otp and Reset
- [ ] `ILForgotPasswordCoordinator` + `AppCoordinator`: push reset view, success → `showLogin(banner: .passwordChanged, prefilledEmail:)`; drop `forgotPasswordDidRequestOtp` / `…EmailReset` (criterion 17)
- [ ] Unit tests: same view for any email, resend restarts timers, success clears a stored session, each error

## Phase 6 — Guest

- [x] "Vào xem trước, chưa đăng nhập" opens Main without a session (`ILLoginViewModel` `.goToGuestPreview`) (criterion 20)
- [ ] `ILSignInPromptView` + `ILAuthGate` in `Presentation/Common/Auth/`, routing to Login / SignUp through `AppCoordinator` (criterion 21); each account feature adopts it in its own spec

## Phase 7 — Strings, logging, QA

- [ ] `vi.json` (+ `en.json` if present): copy of product §3.1.1; delete phone, SMS and forgot-by-phone keys (criterion 22)
- [ ] Check `NetworkLogger` never prints `/v1/auth/*` bodies or `Authorization` (criterion 23)
- [ ] Manual run against the backend dev build: sign-in, wrong credentials, lock, reset on another device ends this session with the message, guest prompt
- [ ] Update the iOS column of product §4.2 when done (tell `ba-writer`)
- [x] Delete `Docs/Specs/ForgotPassword/`, `Login/SRS.md` and the related `Docs/Knowledge`, `Docs/Assumptions`, `Docs/Tech-Debt` files in the docs clean-up step (2026-10-15)
