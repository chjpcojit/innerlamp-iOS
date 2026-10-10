# Tasks — Login

Version: 1.2
Last updated: 2026-09-28
Status: in-progress (Phase 1–3 done; Phase 3's manual on-device QA and Phase
4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature was built retroactively and reconciled with
> `ui-builder` rules (see the feature README changelog). Checked items
> below reflect what shipped; unchecked items are real pending work.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILLoginViewController` extending `BaseViewController`
      (`TransitionProviding` → `CrossFadeTransition`)
- [x] `setupViews()`: `ILNavBar` header, `ILLampGlowView` (`.onLight`),
      title/subtitle, `ILPhoneField` + `ILField` (password, secure +
      `onTrailingTap` "Quên?"), `ILButton` login CTA, `ILButton` SMS CTA,
      footer (`ILDividerRow` + create-account + guest-preview)
- [x] `setupConstraints()`: footer pinned to `keyboardLayoutGuide.topAnchor`,
      scroll area above it, per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state` via `render(state:)`
- [x] Add `ILDividerRow` (generic Design System component) — the only new
      component; all other fields/CTAs reuse SignUp's shared components
- [x] Visual QA against `InnerLamp Prototype.dc.html` (block `isLogin`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILLoginEntity` (`phone`, `password` — pure business fields)
- [x] Create `ILLoginStateModel` (Presentation-side UI state, no UIKit import;
      `nationalDigits` / `isPhoneValid` / `phoneE164` derived values)
- [x] Create `ILLoginUseCase` / `ILLoginUseCaseImpl`:
      - `getInitialState()`
      - `validatePhone(nationalDigits:country:)` (country-aware)
      - `validatePassword(_:)` (non-empty only)
      - `login(_:)` — **stub only** (Phase 3 completes it)
      - `ILLoginError` (`.invalidCredentials`)
- [x] Create `ILLoginRepository` protocol (`login → ILAuthSessionEntity`)
- [x] Create `ILLoginViewModel` (`Input -> Output`, `ILLoginNavEvent`,
      `navigationEventPublisher`)
- [x] Create `ILLoginCoordinator` + `ILLoginCoordinatorDelegate`
- [x] Wire `DIContainer.makeLoginUseCase/ViewModel/Coordinator`
- [x] Wire `AppCoordinator.showLogin()` + conform to
      `ILLoginCoordinatorDelegate`
- [x] Unit tests: `InnerLampTests/ILLoginViewModelTests.swift` (9 tests,
      driven via `Input` publishers, `MockILLoginUseCase`) — covering initial
      state, country change, the four nav events (back/signup/forgot/guest),
      invalid-form no-call, valid-form success, and login-failure stays-on-screen

## Phase 3 — API integration (Data layer built; pending on-device QA)

> Contract confirmed (`Docs/Specs/API/openapi.yaml` v3.9): `POST /v1/auth/login`
> — request `phone_number`, `password` (non-empty), `device` {platform,
> device_model, os_version?, app_version?, device_name?}; success `data` =
> `VerifyOTPData` {access_token, refresh_token, user}. Public
> (`requiresAuth = false`). Failure matrix: `400` VALIDATION_ERROR /
> INVALID_PHONE / INVALID_PASSWORD / INVALID_DEVICE, `401` INVALID_CREDENTIALS
> (wrong password / unknown number / pending-registration-only all collapse;
> 5 fails → 15-min lock), `413`, `429` LOGIN_LOCKED (`details.locked_until`),
> `500` INTERNAL_ERROR.

- [x] Create `ILLoginDTO` + `ILLoginMapper` (`Data/DTOs/` + `Data/DTOs/Mappers/`)
      — one type per wire shape, per the contract above
- [x] Extend `ILLoginEntity` (or decide to derive `device` at the Data boundary)
      — decided: `device` is derived at the Data boundary
      (`ILLoginRepositoryImpl.currentDevice()`, from `UIDevice`/`Bundle`), per
      design.md gap #1's second option — `ILLoginEntity` is unchanged
- [x] Create the `LoginEndpoint` conformance under `Data/DataSources/Remote/`
      (`POST /v1/auth/login`, `requiresAuth = false`, body from the request DTO)
- [x] Create `ILLoginRepositoryImpl` (`Data/Repositories/`) wrapping
      `NetworkService`; map `NetworkError` → `ILLoginError` at the boundary
- [x] Extend `ILLoginError` with the contract's failure cases (`.invalidPhone`,
      `.invalidPassword`, `.invalidDevice`, `.invalidCredentials`, `.loginLocked`,
      `.server`, `.networkUnavailable`, `.timedOut`) — read 429 timing from
      `details.locked_until`, reusing `ILUnlockTimeFormatter`; add matching
      `login.error.*` keys to `vi.json`. Also added `.storageFailed` (same
      precedent as `ILOtpError.storageFailed`) for a post-login Keychain/local
      user store write failure.
- [x] Inject `ILLoginRepository` into `ILLoginUseCaseImpl.init` and replace the
      `login` stub body with the real repository call — success now also
      stores the session (access/refresh token in Keychain, user in
      `ILUserRepository`), same pattern as `ILOtpUseCaseImpl.verifyCode`. The
      shared refresh-token Keychain key moved from `ILOtpUseCaseImpl` to
      `KeychainAuthTokenProviding.refreshTokenKey` (both features write the
      same key; this was the refactor `ILOtpUseCaseImpl`'s own doc comment
      anticipated).
- [x] Update `ILLoginViewModelTests` + add a mock repository to cover real
      success/failure paths (the current `MockILLoginUseCase` stays for the
      validation/nav tests) — done as `InnerLampTests/ILLoginUseCaseTests.swift`
      (mocks `ILLoginRepository`, mirrors `ILOtpUseCaseTests.swift`) plus
      `InnerLampTests/ILLoginRepositoryTests.swift` (DTO/mapper/endpoint/error
      mapping, mirrors `ILSignUpRepositoryTests.swift`); `ILLoginViewModelTests`
      itself needed no changes since it only depends on the `ILLoginUseCase`
      protocol, which kept its signature.
- [ ] Manual test against a real/staging backend once available — local dev
      backend confirmed reachable 2026-09-28 (`APIConfig.serverBaseURL` `.dev`
      now points at it); pending the user's on-device QA pass.

## Phase 4 — SMS-code login (pending, separate scope)

- [ ] Decide whether "Đăng nhập bằng mã SMS" routes through the existing OTP
      feature or needs its own OTP-for-login flow — the contract's
      `ResendOTPRequest.purpose` enum already lists `login`, but notes
      "US-001 only implements register; the other three return
      UNSUPPORTED_OTP_PURPOSE" (see ⚠️ in `requirements.md`)
- [ ] Wire `handleSmsCodeTapped()` to a nav event / coordinator action once the
      OTP-for-login flow exists
- [ ] Update `InnerLamp/Presentation/Scenes/Login/README.md` changelog

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Login/README.md` (implementation notes,
      design comparison table, changelog)
- [ ] `Docs/Knowledge/features/login.md` (OKF concept) — hold off until the
      login API (Phase 3) lands, so the concept describes real end-to-end
      behavior instead of a stub. See `Docs/Specs/OKF.md`.
