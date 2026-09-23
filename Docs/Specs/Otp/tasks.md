# Tasks — Otp

Version: 1.1
Last updated: 2026-09-23
Status: in-progress (Phase 3 API integration done bar the manual real-backend
test; contract confirmed in `Docs/Specs/API/openapi.yaml` v3.9)

> See `changelog.md` in this folder for the version history of this spec.

> Checked items reflect what already shipped (the OTP screen was built UI-first, like SignUp);
> unchecked items are real pending work, not hypothetical examples. Phase 3 is written before it
> is implemented.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILOtpViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: header, title/subtitle + "Đổi số", `ILCodeInputView`,
      `ILOtpResendRowView`, `ILOtpVoiceCallBannerView`, footer (verify `ILButton` + expiry label)
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render `Output.state`
- [x] Feature-scoped views `ILOtpResendRowView`, `ILOtpVoiceCallBannerView` under `Views/`
- [x] `ILOtpCoordinator` + `ILOtpCoordinatorDelegate`, wired by `AppCoordinator.showOtp`
- [x] Unit tests `InnerLampTests/ILOtpViewModelTests.swift` (9 cases, `MockILOtpUseCase`)

## Phase 2 — Domain + local logic

- [x] `ILOtpUseCase` / `ILOtpUseCaseImpl`: `getInitialState`, `resendCode`/`verifyCode` **as
      one-line `print("TODO: …")` stubs** (no network, no fabricated success)
- [x] `ILOtpError.invalidCode` + `ILOtpChannel` (`.sms` / `.voiceCall`)
- [x] `ILOtpStateModel` (countdown, `isCodeComplete`, `isSubmitEnabled`, `canResend`)

## Phase 3 — API integration (pending)

> Contract confirmed (`Docs/Specs/API/openapi.yaml` v3.9):
> `POST /v1/auth/register/verify-otp` (request `phone_number`, `otp_code`; success `201` →
> `{access_token, refresh_token, user}`); `POST /v1/auth/resend-otp` (request `phone_number`,
> `purpose = "register"`; success `200` → `{message, expires_in_seconds, resend_after_seconds,
> resend_remaining}`). Both public (`requiresAuth = false`). Session persistence decided
> 2026-09-23: Keychain (access + refresh) + `ILUserRepository`, inside the UseCase.

- [x] Create `ILOtpTimingEntity` (`Domain/Entities/`) — `expiresInSeconds`, `resendAfterSeconds`
- [x] Create `ILOtpVerifyRequestDTO` / `ILOtpVerifyResponseDTO` / `ILOtpUserDTO` /
      `ILOtpResendRequestDTO` / `ILOtpResendResponseDTO` in `Data/DTOs/ILOtpDTO.swift`
- [x] Create `ILOtpMapper` (`Data/DTOs/Mappers/`) — DTO → `ILAuthSessionEntity` / `ILOtpTimingEntity`
- [x] Create `VerifyRegistrationOTPEndpoint` + `ResendOTPEndpoint` (`Data/DataSources/Remote/`),
      unprefixed `<Action>Endpoint`, `requiresAuth = false`
- [x] Create `ILOtpRepository` protocol (`Domain/Repositories/`) + `ILOtpRepositoryImpl`
      (`Data/Repositories/`) wrapping `NetworkService`
- [x] Extend `ILOtpError` with the contract's failure cases and add
      `ILOtpError.from(_ error: NetworkError, operation:)` — exhaustive, reading
      `NetworkError.apiError(code:message:type:details:)`; add the `otp.error.*` keys to
      `vi.json`, reusing the identical `signup.error.*` messages where the text is the same
- [x] Inject `ILOtpRepository`, `KeychainService`, `ILUserRepository` into `ILOtpUseCaseImpl`:
      replace both stub bodies; store the session on verify success; make `.voiceCall` throw
      `.voiceCallUnsupported` without a network call
- [x] Wire `makeOtpRepository()` + the new constructor args in `DIContainer`
- [x] Seed the OTP screen's countdown and expiry from the server: extend `ILOtpStateModel`,
      `ILOtpViewModel`, `ILOtpCoordinator`, `ILOtpViewController`, and pass the initial timing
      through `AppCoordinator.showOtp`
- [x] SignUp side: `sendVerificationCode` returns `ILSignUpOTPEntity`; the
      `.didRequestVerification` event and `ILSignUpCoordinatorDelegate` carry
      `otpExpiresInSeconds` / `resendAfterSeconds` (resolves the long-open SignUp ⚠️)
- [x] Update `ILOtpViewModelTests` + add `MockILOtpRepository`; add `ILOtpRepositoryTests`
      (error mapping + mapper + wire shapes) and `ILOtpUseCaseTests` (session persistence,
      resend timing, voice-call refusal)
- [ ] Manual test against a real/staging backend once available — verify success, `OTP_INVALID`,
      `OTP_EXPIRED`, `PENDING_REGISTRATION_EXPIRED`, `OTP_LOCKED`, resend cooldown, offline/timeout

## Phase 4 — Documentation

- [x] Update `InnerLamp/Presentation/Scenes/Otp/README.md` (status table + changelog) now that
      the UseCase is real
- [ ] `Docs/Knowledge/features/otp.md` (OKF concept) — after Phase 3 lands

## Deferred (not blocking this feature)

- [ ] Voice-call OTP channel — needs a confirmed backend contract (the `ResendOTPRequest` has no
      channel field). Until then the banner shows a "not available yet" message and makes no call.
- [ ] `POST /v1/auth/login` and `POST /v1/auth/refresh` — separate features; the refresh token is
      stored here but never exchanged yet.
- [ ] `user.created_at` — not modeled by `ILUserEntity` / the Core Data store.
