# Tasks — Login

Version: 1.1
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3–4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature was built retroactively and reconciled with
> `il-screen-builder` rules (see the feature README changelog). Checked items
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

## Phase 3 — API integration (pending; contract confirmed, Data layer not built)

> Contract confirmed (`Docs/Specs/API/openapi.yaml` v3.9): `POST /v1/auth/login`
> — request `phone_number`, `password` (non-empty), `device` {platform,
> device_model, os_version?, app_version?, device_name?}; success `data` =
> `VerifyOTPData` {access_token, refresh_token, user}. Public
> (`requiresAuth = false`). Failure matrix: `400` VALIDATION_ERROR /
> INVALID_PHONE / INVALID_PASSWORD / INVALID_DEVICE, `401` INVALID_CREDENTIALS
> (wrong password / unknown number / pending-registration-only all collapse;
> 5 fails → 15-min lock), `413`, `429` LOGIN_LOCKED (`details.locked_until`),
> `500` INTERNAL_ERROR.

- [ ] Create `ILLoginDTO` + `ILLoginMapper` (`Data/DTOs/` + `Data/DTOs/Mappers/`)
      — one type per wire shape, per the contract above
- [ ] Extend `ILLoginEntity` (or decide to derive `device` at the Data boundary)
      — the contract requires a `device` object the entity does not yet carry
- [ ] Create the `LoginEndpoint` conformance under `Data/DataSources/Remote/`
      (`POST /v1/auth/login`, `requiresAuth = false`, body from the request DTO)
- [ ] Create `ILLoginRepositoryImpl` (`Data/Repositories/`) wrapping
      `NetworkService`; map `NetworkError` → `ILLoginError` at the boundary
- [ ] Extend `ILLoginError` with the contract's failure cases (`.invalidPhone`,
      `.invalidPassword`, `.invalidDevice`, `.invalidCredentials`, `.loginLocked`,
      `.server`, `.networkUnavailable`, `.timedOut`) — read 429 timing from
      `details.locked_until`, reusing `ILUnlockTimeFormatter`; add matching
      `login.error.*` keys to `vi.json`
- [ ] Inject `ILLoginRepository` into `ILLoginUseCaseImpl.init` and replace the
      `login` stub body with the real repository call
- [ ] Update `ILLoginViewModelTests` + add a mock repository to cover real
      success/failure paths (the current `MockILLoginUseCase` stays for the
      validation/nav tests)
- [ ] Manual test against a real/staging backend once available

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
