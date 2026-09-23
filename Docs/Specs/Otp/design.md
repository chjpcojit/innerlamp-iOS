# Design — Otp

Version: 1.1
Last updated: 2026-09-23
Status: in-progress — UI + local logic + API integration done; only the
manual real-backend test pending (`tasks.md` Phase 3)

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Otp follows MVVM-C + Clean Architecture per `AGENTS.md` and `Core/Base/README.md`.
It is **not** an isolated section: `ILOtpCoordinator` is pushed on top of the
existing stack by `AppCoordinator` (from SignUp or ForgotPassword) and `finish()`es
when verification succeeds or the user goes back.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILOtpTimingEntity.swift` (new) | OTP-delivery timing returned by the server: `expiresInSeconds`, `resendAfterSeconds`. Drives the countdown and the expiry copy. |
| Domain / Entity — SignUp side | `Domain/Entities/ILSignUpOTPEntity.swift` (new, SignUp) | `request-otp` metadata (`message`, `expiresInSeconds`, `resendAfterSeconds`) carried from SignUp to this screen. Existence resolves SignUp's long-open response-shape ⚠️. |
| Domain / UseCase | `Domain/UseCases/Otp/ILOtpUseCase.swift` | `getInitialState(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:)`; `resendCode(phoneNumber:channel:) async throws -> ILOtpTimingEntity`; `verifyCode(phoneNumber:code:) async throws`. Owns `ILOtpError`. On verify success, persists the session (Keychain + `ILUserRepository`). |
| Domain / Repository — new | `Domain/Repositories/ILOtpRepository.swift` | Entity only: `verifyRegistrationOTP(phoneNumber:code:) -> ILAuthSessionEntity`; `resendRegistrationOTP(phoneNumber:) -> ILOtpTimingEntity`. No DTO, no `NetworkError` above this line. |
| Data / Repository — new | `Data/Repositories/ILOtpRepositoryImpl.swift` | Wraps `NetworkService`; owns the Endpoints + Mapper; maps `NetworkError` → `ILOtpError` (verify/resend-aware). |
| Data / DTO — new | `Data/DTOs/ILOtpDTO.swift` | `ILOtpVerifyRequestDTO` (snake_case `CodingKeys`), `ILOtpVerifyResponseDTO`, `ILOtpUserDTO`, `ILOtpResendRequestDTO` (snake_case `CodingKeys`), `ILOtpResendResponseDTO`. |
| Data / Mapper — new | `Data/DTOs/Mappers/ILOtpMapper.swift` | `ILOtpVerifyResponseDTO → ILAuthSessionEntity`, `ILOtpResendResponseDTO → ILOtpTimingEntity`. Never touches `ILOtpStateModel`. |
| Data / Endpoint — new | `Data/DataSources/Remote/VerifyRegistrationOTPEndpoint.swift`, `ResendOTPEndpoint.swift` | Unprefixed `<Action>Endpoint`; `POST /v1/auth/register/verify-otp` and `POST /v1/auth/resend-otp`; both `requiresAuth = false`. |
| Presentation / State | `Presentation/Scenes/Otp/ILOtpStateModel.swift` | Adds `otpExpiresInSeconds` and `resendError`; `secondsRemaining` is now seeded from the server instead of a fixed 47s constant. |
| Presentation / ViewModel | `Presentation/Scenes/Otp/ILOtpViewModel.swift` | Seeds the countdown/expiry from the injected timing; uses the timing a resend returns; surfaces resend failures. |
| Presentation / Coordinator | `Presentation/Scenes/Otp/ILOtpCoordinator.swift` | Takes/passes the initial timing; forwards `didVerify`. |
| Presentation / ViewController | `Presentation/Scenes/Otp/ILOtpViewController.swift` | Renders the expiry copy from the state model instead of a static string. |
| **Modified** — SignUp | `ILSignUpUseCase` / `ILSignUpRepository` / `ILSignUpMapper` / `ILSignUpViewModel` / `ILSignUpCoordinator` / `AppCoordinator` | `sendVerificationCode` now returns `ILSignUpOTPEntity`; `.didRequestVerification` carries `otpExpiresInSeconds` / `resendAfterSeconds`; `AppCoordinator.showOtp` forwards them. |

## Navigation flow

```
AppCoordinator
  └─ showSignUp() → ILSignUpCoordinator
       (tap "Gửi mã xác thực") → didRequestVerification(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:)
         → AppCoordinator.showOtp(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:)
              ILOtpCoordinator (pushed on top of the SignUp stack)
                (tap "Xác nhận") → verify → otpDidVerify → AppCoordinator.showMain()
                (back / "Đổi số") → pop → back to SignUp
  └─ showForgotPassword() → (its OTP branch) → showOtp(phoneNumber:defaults)   [ForgotPassword's own request is unimplemented]
```

## Data flow (verify)

1. `ILOtpViewController.handleVerifyTapped()` → `verifyTappedSubject`.
2. `ILOtpViewModel.handleVerifyTapped()`:
   - Guard `currentState.isSubmitEnabled` (6 digits, not already verifying).
   - `isVerifying = true`, clear `codeError`/`resendError`, emit state.
   - `Task` → `useCase.verifyCode(phoneNumber:code:)`.
3. `ILOtpUseCaseImpl.verifyCode`:
   - `repository.verifyRegistrationOTP(phoneNumber:code:)` → `ILAuthSessionEntity`.
   - Persist: `access_token` → Keychain under `KeychainAuthTokenProviding.accessTokenKey`;
     `refresh_token` → Keychain under the refresh key; `user` →
     `ILUserRepository.saveUser(_:)`.
   - Any persistence failure throws `ILOtpError.storageFailed` (the account is
     already created at this point — see "Known edge cases").
4. Success → `isVerifying = false`, emit `.didVerify(phoneNumber:)`; the
   coordinator forwards to `AppCoordinator.showMain()`.
5. Failure → `isVerifying = false`, `codeError = error.localizedDescription`,
   no navigation.

## Data flow (resend)

1. `handleResendTapped()` guards `currentState.canResend`; the voice-call banner
   → `handleRequestVoiceCallTapped()`.
2. `requestNewCode(channel:)` sets `isResending = true`, then:
   - `.voiceCall` → `useCase.resendCode(..., .voiceCall)` throws
     `.voiceCallUnsupported` **without any network call** (deferred channel).
   - `.sms` → `repository.resendRegistrationOTP(phoneNumber:)` →
     `ILOtpTimingEntity`.
3. Success → `isResending = false`, clear `code`/errors, and reseed
   `secondsRemaining` / `otpExpiresInSeconds` from the returned timing, then
   restart the countdown.
4. Failure → `isResending = false`, `resendError = error.localizedDescription`,
   keep the entered code.

## Step-by-step Flow — verify / resend

Contract: `Docs/Specs/API/openapi.yaml` v3.9. Both routes are public, speak the
standard `ApiResponse` envelope, and discriminate failures by `error.code`.

```
Step 1 — Verify the code (this feature)
- Trigger: user taps "Xác nhận", 6 digits entered
- Pre-condition: a live pending_registration exists for the number
- API: POST /v1/auth/register/verify-otp  Body: phone_number, otp_code
    - Success (201) → data {access_token, refresh_token, user}; store session,
      navigate to the main app
    - Failure (400 OTP_INVALID) → invalid-code message, keep the code, allow retry
    - Failure (400 OTP_EXPIRED) → expired-code message, prompt to resend
    - Failure (400 PENDING_REGISTRATION_EXPIRED) → restart-registration message
    - Failure (409 PHONE_TAKEN / EMAIL_TAKEN) → taken message
    - Failure (429 OTP_LOCKED) → locked message
    - Failure (500 INTERNAL_ERROR) → shared generic error
    - Failure (transport: noInternetConnection / timeout) → shared no-internet / retry error

Step 2 — Resend (this feature)
- Trigger: "Gửi lại" after the cooldown, or the voice-call banner
- Pre-condition: pending_registration still alive (≤ 24h)
- API: POST /v1/auth/resend-otp  Body: phone_number, purpose = "register"
    - Success (200) → data {message, expires_in_seconds, resend_after_seconds};
      reseed the countdown/expiry, then restart
    - Failure (400 OTP_INVALID — no pending registration) → restart-registration message
    - Failure (400 PENDING_REGISTRATION_EXPIRED) → restart-registration message
    - Failure (429 OTP_RESEND_TOO_SOON) → "try again in N seconds" when
      details.retry_after_seconds is present
    - Failure (429 OTP_LOCKED / OTP_SEND_LIMITED) → locked/limited message
    - Failure (500 SMS_SEND_FAILED / INTERNAL_ERROR) → shared generic error
- Voice-call banner: NO network call — the confirmed request has no channel.
```

## Session persistence

`verify-otp` returns the account's first session. Persisting it is the last step
of `ILOtpUseCaseImpl.verifyCode`, so the UseCase signature (`... -> Void`) the
ViewModel already calls does not change:

| Value | Destination | Key / API |
|---|---|---|
| `access_token` | Keychain | `KeychainAuthTokenProviding.accessTokenKey` (`"access_token"`) — read automatically by every authenticated request |
| `refresh_token` | Keychain | a dedicated `"refresh_token"` key, consumed once the refresh flow exists |
| `user` | `ILUserRepository` (Core Data) | `saveUser(_:)` |

`ILUserEntity` does not model the server's `user.created_at`; the user DTO omits
it rather than letting the mapper silently drop a decoded field. Add it to the
Domain entity and the Core Data model when something needs it.

## Known edge cases

- **Persistence fails after the account is created.** `verify-otp` creates the
  account and the pending registration is gone, so retrying the same call cannot
  succeed. The screen surfaces `storageFailed`; the user can log in instead. Not
  auto-recovered — a retry/recovery policy is out of scope.
- **`OTP_INVALID` means two different things.** On verify it is a wrong code; on
  resend it is "no pending registration". `ILOtpError.from(_:operation:)` takes
  the operation so the two callers map it correctly.
- **SignUp's response shape changed.** `sendVerificationCode` now returns
  `ILSignUpOTPEntity` instead of `Void`; the ViewModel and its tests were updated
  together (see `Docs/Specs/SignUp/changelog.md` v1.12).

## Design reference

Matches the OTP screen in `Docs/design_handoff_innerlamp/design/InnerLamp
Prototype.dc.html`. The handoff's fixed "Gửi lại mã sau 00:47" and "Mã có hiệu
lực trong 10 phút" are superseded by the server's confirmed 60s / 90s values.
