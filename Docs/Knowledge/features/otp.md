---
type: Feature
title: OTP Verification
description: Post-signup verification screen — the user enters the 6-digit code sent to their phone, verifies it against the server, stores the session, and lands in the main app; also handles resend and the deferred voice-call channel.
resource: InnerLamp/Presentation/Scenes/Otp/
tags: [auth, mvvm-c]
status: draft
generated: { by: claude-code, at: 2026-09-27T14:54:58+07:00 }
sources:
  - path: Docs/Specs/Otp/requirements.md
    kind: spec
  - path: Docs/Specs/Otp/design.md
    kind: spec
  - path: InnerLamp/Domain/UseCases/Otp/ILOtpUseCase.swift
    kind: code
  - path: InnerLamp/Domain/Repositories/ILOtpRepository.swift
    kind: code
  - path: InnerLamp/Data/Repositories/ILOtpRepositoryImpl.swift
    kind: code
  - path: InnerLamp/Data/DataSources/Remote/VerifyRegistrationOTPEndpoint.swift
    kind: code
  - path: InnerLamp/Data/DataSources/Remote/ResendOTPEndpoint.swift
    kind: code
---

# Summary

OTP is the second half of the registration flow. It receives the phone number
and the server's real delivery timing (`expires_in_seconds` /
`resend_after_seconds`) from SignUp's `request-otp` response, shows a 6-digit
code input seeded from that timing, and on a verified code creates the account,
stores the returned session, and navigates to the main app. It also handles
"Gửi lại" (resend) and renders a voice-call banner that is deliberately a no-op
until a voice channel exists in the contract.

On success, `ILOtpUseCaseImpl.verifyCode` stores the session as the last step:
`access_token` → Keychain (`KeychainAuthTokenProviding.accessTokenKey`),
`refresh_token` → Keychain (`"refresh_token"`), and `user` → `ILUserRepository`
(Core Data). On any failure the user stays on the screen, keeps the code, and
sees a message discriminated by the server's `error.code` (never the
human-readable message).

**Current limitation**: both network calls (`verify-otp` / `resend-otp`) are
real and unit-tested, but the flow has not been exercised against a real/staging
backend — see [Pending work](#pending-work).

# Architecture

MVVM-C + Clean Architecture, same shape as SignUp. `ILOtpCoordinator` is
**pushed on top of the existing stack** by `AppCoordinator` (from SignUp, or
from ForgotPassword's stopgap reuse) and `finish()`es when verification
succeeds or the user goes back.

| Layer | Type | File |
|---|---|---|
| Domain / Entity | Domain Entity | `Domain/Entities/ILOtpTimingEntity.swift` — `expiresInSeconds` / `resendAfterSeconds` delivered by the server; drives the countdown and expiry copy |
| Domain / Entity (shared) | Domain Entity | `Domain/Entities/ILAuthSessionEntity.swift` — `accessToken` / `refreshToken` / `user`; returned by verify, also the Login contract's response shape |
| Domain / UseCase | UseCase | `Domain/UseCases/Otp/ILOtpUseCase.swift` — `getInitialState`, `resendCode(phoneNumber:channel:)`, `verifyCode(phoneNumber:code:)`; owns `ILOtpError`, `ILOtpOperation`, `ILOtpPurpose`, `ILOtpChannel`; persists the session on verify success |
| Domain / Repository | Repository protocol | `Domain/Repositories/ILOtpRepository.swift` — `verifyRegistrationOTP` / `resendRegistrationOTP`; Entity in / Entity out, no DTO or `NetworkError` above it |
| Data / Repository | Repository impl | `Data/Repositories/ILOtpRepositoryImpl.swift` — owns the two Endpoints + Mapper; maps `NetworkError` → `ILOtpError` (verify/resend-aware) |
| Data / DTO | DTO | `Data/DTOs/ILOtpDTO.swift` — `ILOtpVerifyRequestDTO` / `ILOtpVerifyResponseDTO` / `ILOtpUserDTO` / `ILOtpResendRequestDTO` / `ILOtpResendResponseDTO` |
| Data / Mapper | Mapper | `Data/DTOs/Mappers/ILOtpMapper.swift` — DTO → `ILAuthSessionEntity` / `ILOtpTimingEntity`, never touches `ILOtpStateModel` |
| Data / Endpoint | Endpoint | `Data/DataSources/Remote/VerifyRegistrationOTPEndpoint.swift` — `POST /v1/auth/register/verify-otp`, `requiresAuth = false` |
| Data / Endpoint | Endpoint | `Data/DataSources/Remote/ResendOTPEndpoint.swift` — `POST /v1/auth/resend-otp` (`purpose = "register"`), `requiresAuth = false` |
| Presentation / State | State Model | `Presentation/Scenes/Otp/ILOtpStateModel.swift` — UI-only (code, errors, `secondsRemaining`, `otpExpiresInSeconds`, derived `isCodeComplete` / `isSubmitEnabled` / `canResend` / `expiryText`) |
| Presentation / ViewModel | ViewModel | `Presentation/Scenes/Otp/ILOtpViewModel.swift` — `Input -> Output` per `ViewModelType`; owns the countdown `Timer` and `ILOtpNavEvent` |
| Presentation / Coordinator | Coordinator | `Presentation/Scenes/Otp/ILOtpCoordinator.swift` — takes/passes the initial timing; `goBack` → pop + finish, `didVerify` → delegate |
| Presentation / ViewController | ViewController | `Presentation/Scenes/Otp/ILOtpViewController.swift` |
| Feature-scoped views | View | `Presentation/Scenes/Otp/Views/ILOtpResendRowView.swift`, `ILOtpVoiceCallBannerView.swift` |
| Tests | Unit tests | `InnerLampTests/ILOtpViewModelTests.swift`, `ILOtpRepositoryTests.swift`, `ILOtpUseCaseTests.swift` |

Reuses Design System components (`ILNavBar`, `ILCodeInputView`, `ILButton`,
`ILTypography`, `ILColors`, `ILMetrics`) — no new shared component was introduced
by this feature.

# Navigation

```
AppCoordinator
  ├─ showSignUp() → ILSignUpCoordinator
  │     (request-otp success) → signUpDidRequestVerification(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:)
  │        → AppCoordinator.showOtp(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:)
  │             ILOtpCoordinator (pushed on top of the SignUp stack)
  │               (tap "Xác nhận", verify success) → otpDidVerify → AppCoordinator.showMain()
  │               (back / "Đổi số") → pop → back to SignUp
  └─ showForgotPassword() → ILForgotPasswordCoordinator
        (its OTP branch, stopgap) → showOtp(phoneNumber:defaultOTPExpirySeconds, defaultResendCooldownSeconds)
```

`AppCoordinator.showOtp` is also reachable from ForgotPassword, but that path
falls back to `ILOtpStateModel.defaultOTPExpirySeconds` (90) /
`defaultResendCooldownSeconds` (60) because ForgotPassword's own OTP request is
not implemented — see [Related concepts](#related-concepts).

# Submit flow and error mapping

`handleVerifyTapped()` guards `isSubmitEnabled` (6 digits, not already
verifying), then calls `useCase.verifyCode(...)`. The chain is:

```
ILOtpViewModel
  → ILOtpUseCaseImpl.verifyCode(phoneNumber:code:)
      → ILOtpRepositoryImpl.verifyRegistrationOTP(phoneNumber:code:)
          → VerifyRegistrationOTPEndpoint → NetworkService → ILOtpVerifyResponseDTO
          → ILOtpMapper.toDomain → ILAuthSessionEntity
          catch NetworkError → ILOtpError.from(_:operation:.verify)
      → persist session (Keychain access/refresh + ILUserRepository.saveUser)
        catch → ILOtpError.storageFailed
  → .didVerify(phoneNumber:)  or  codeError set, stay on screen
```

`ILOtpError.from(_:operation:)` discriminates on the envelope's `error.code`
(read from `NetworkError.apiError`), with `details` supplying the 429 timing.
`operation` disambiguates the codes the two calls share (`OTP_INVALID` is a wrong
code on verify, "no pending registration" on resend):

| Server `error.code` | verify → | resend → | Copy |
|---|---|---|---|
| `OTP_INVALID` | `.invalidCode` | `.registrationExpired` | `otp.error.invalidCode` / `otp.error.registrationExpired` |
| `OTP_EXPIRED` | `.codeExpired` | — | `otp.error.expiredCode` |
| `PENDING_REGISTRATION_EXPIRED` | `.registrationExpired` | `.registrationExpired` | `otp.error.registrationExpired` |
| `PHONE_TAKEN` / `EMAIL_TAKEN` | `.phoneTaken` / `.emailTaken` | same | `signup.error.phoneTaken` / `emailTaken` |
| `OTP_LOCKED` | `.otpLocked(lockedUntil:)` | same | `signup.error.otpLocked(Until)` |
| `OTP_SEND_LIMITED` | `.sendLimited(lockedUntil:)` | same | `signup.error.otpSendLimited(Until)` |
| `OTP_RESEND_TOO_SOON` | — | `.resendTooSoon(retryAfterSeconds:)` | `signup.error.otpResendTooSoon(Seconds)` |
| `SMS_SEND_FAILED` | `.smsSendFailed` | same | `signup.error.smsSendFailed` |
| `VALIDATION_ERROR` / `INVALID_EMAIL` / `INVALID_PHONE` / `INVALID_PASSWORD` / `PAYLOAD_TOO_LARGE` | `.invalidInput` | `.invalidInput` | `signup.error.invalidInput` |
| — (transport) | `.networkUnavailable` / `.timedOut` | same | `error.no_internet` / `signup.error.timedOut` |
| anything else | `.server` | `.server` | `error.generic` |

The OTP-locked / send-limited / resend-too-soon cases reuse SignUp's identical
`signup.error.*` messages rather than duplicating them under `otp.*`. `.voiceCallUnsupported`
and `.storageFailed` are OTP-only.

# Resend and the voice-call banner

`handleResendTapped()` guards `canResend` (`secondsRemaining <= 0 && !isResending`).
On success the returned `ILOtpTimingEntity` reseeds `secondsRemaining` and
`otpExpiresInSeconds` and restarts the countdown; on failure `resendError` is set
and the entered code is kept. The voice-call banner routes through
`resendCode(channel: .voiceCall)`, which throws `.voiceCallUnsupported`
**without any network call** — the confirmed `resend-otp` contract has no
channel field (see [Related concepts](#related-concepts)).

# Pending work

- The integration has not been exercised against a real/staging backend
  (`Docs/Specs/Otp/tasks.md` Phase 3 keeps exactly one unchecked item: manual
  success / `OTP_INVALID` / `OTP_EXPIRED` / `PENDING_REGISTRATION_EXPIRED` /
  `OTP_LOCKED` / resend-cooldown / offline-timeout runs).
- The voice-call OTP channel is deferred: the banner shows a "not available yet"
  message and makes no call until a voice channel is confirmed in the contract.
- `user.created_at` is not modeled by `ILUserEntity` / Core Data and is not
  persisted; the `ILOtpUserDTO` omits it rather than silently dropping it.
- Promote to `stable` once the end-to-end flow is verified against a
  real/staging backend.

# Related concepts

- [Sign Up](signup.md) (`InnerLamp/Presentation/Scenes/SignUp/`) — the first half
  of registration; its `request-otp` response carries the timing that seeds this
  screen's countdown and expiry copy via `.didRequestVerification`.
- [Forgot Password](forgot-password.md)
  (`InnerLamp/Presentation/Scenes/ForgotPassword/`) — reuses this screen as a
  stopgap (with default timing), but its OTP request targets a reset purpose
  that is not yet distinguished.
- [Login](login.md) (`InnerLamp/Presentation/Scenes/Login/`) — the "Đăng nhập
  bằng mã SMS" flow would reuse this screen, but no OTP-for-login flow is wired
  yet.
- `verify-otp` / `resend-otp` endpoint concepts
  (`[auth-verify-otp](../api/auth-verify-otp.md)`,
  `[auth-resend-otp](../api/auth-resend-otp.md)`) — the wire contracts this
  feature's Data layer implements.
