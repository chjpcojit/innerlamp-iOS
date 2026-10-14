# Design — Onboarding

Version: 2.0
Last updated: 2026-10-14
Status: in-progress (drift) — splash, intro, SignUp and the code screen built on the phone + SMS contract; v2.0 changes are planned (email code, launch routing, website terms pages, temple proposal sent)

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. Five scenes, all wired by `AppCoordinator` (cross-section
flow): `Splash` → `Onboarding` (intro) → `SignUp` → `Otp` (email code) → Main; `AddTemple` is presented
from SignUp. v2.0 keeps the scene structure and changes what flows through it:

- **Identifier is the email.** The code screen is keyed by the email; `phoneNumber` disappears from
  the Otp entities, endpoints and coordinator arguments.
- **Phone is sent as typed.** `phone_country` (ISO from `ILCountry.iso`) + `phone_number` (the digits
  the user typed); the app stops building the grouped `+84 912 345 678` string for the wire.
- **Launch routing** ends on Login, not SignUp, when the intro was seen and no session is stored.
- **Terms unchanged** for now: the bundled legal sheet stays (BR-ONB-11 one-text part deferred).
- **Temple proposal is sent** after the account exists (was kept on the device only).

## Layers & components

| Layer | File | Responsibility | State |
|---|---|---|---|
| Splash / UseCase | `Domain/UseCases/Splash/ILSplashUseCase.swift` | `isOnboardingCompleted()`, `hasSession()` (deletes a Keychain session on a fresh install first). | built — criterion 2 |
| Splash / ViewModel | `Presentation/Scenes/Splash/ILSplashViewModel.swift` | Route after the splash: `.goToMain` / `.goToOnboarding` / `.goToLogin`. | **change**: replace `.goToSignup` with `.goToLogin` (criterion 1) |
| App / Coordinator | `App/AppCoordinator.swift` | `splashDidRequestLogin` → `showLogin()` (root); `showOtp(email:otpExpiresInSeconds:resendAfterSeconds:)`; `showSignUp(asRoot:)` only from Login / intro now. | **change**: splash route, `showOtp` argument, drop `splashDidRequestSignup` |
| Intro / UseCase | `Domain/UseCases/Onboarding/ILOnboardingUseCase.swift` | `savePreferences` (wishes, bells, sets `has_completed_onboarding`), `markOnboardingCompleted()`. | built |
| Intro / ViewModel | `Presentation/Scenes/Onboarding/ILOnboardingViewModel.swift` | Steps, toggles, "Bỏ qua", "Tạo tài khoản". | **change**: "Tôi đã có tài khoản" (back on step 1) calls `savePreferences` before `.goToLogin` (criterion 4) |
| SignUp / Entity | `Domain/Entities/ILSignUpEntity.swift` | `fullName`, `dharmaName?`, `ordinationTempleID?`, `phoneCountry` (ISO), `phoneNumber` (typed digits), `email`, `password`. | **change**: add `phoneCountry`; `displayName` → `dharmaName` optional; email is the identifier |
| SignUp / Validation | `Domain/Validation/ILEmailValidator.swift`, new `Domain/Validation/ILSignUpRules.swift` | Pure functions for BR-ONB-04…07: `normalizePhone(digits:country:)`, `normalizeEmail`, `passwordLength` (characters after `precomposedStringWithCanonicalMapping`), `checkNames`. Used by the UseCase and by the vector tests. | **change**: password max 64 and NFC count, full name ≤ 300, dharma name optional ≤ 255, email ≤ 254 + lowercase |
| SignUp / UseCase | `Domain/UseCases/SignUp/ILSignUpUseCase.swift` | `validate…` via `ILSignUpRules`, suggestions, strength (3 levels, advice), `sendVerificationCode(_:) -> ILSignUpOTPEntity`; `ILSignUpError`. | **change**: dharma name no longer required or pre-filled; errors: drop `emailTaken` / `smsSendFailed` / `otpLocked`; add `emailSendFailed`, `rateLimited(retryAfter:)` |
| SignUp / Data | `Data/DTOs/ILSignUpDTO.swift`, `Data/DTOs/Mappers/ILSignUpMapper.swift`, `Data/DataSources/Remote/RequestOTPEndpoint.swift`, `Data/Repositories/ILSignUpRepositoryImpl.swift` | Request DTO with `email`, `password`, `phone_country`, `phone_number`, `full_name`, `dharma_name?`, `ordination_temple_id?` (omitted when nil); error-code mapping. | **change**: DTO fields; mapping per the Error → UI table |
| SignUp / State | `Presentation/Scenes/SignUp/ILSignUpStateModel.swift` | Field values and errors, strength, submitting, kept proposal. | **change**: drop `phoneE164`; dharma name empty by default; `phoneError` can carry the Login link |
| SignUp / ViewModel | `Presentation/Scenes/SignUp/ILSignUpViewModel.swift` | Submit (criteria 9, 13, 16), `.didRequestVerification(email:timing:)`, `.goToLogin`, restore from a returned form. | **change** |
| SignUp / ViewController | `Presentation/Scenes/SignUp/ILSignUpViewController.swift`, `Views/ILDharmaNameSuggestionField.swift`, `Views/ILOrdinationPlaceFieldView.swift` | Form, button "Đăng ký", email hint, terms links. | **change**: copy (§3.1.1), dharma name empty, email hint |
| SignUp / Legal | `Views/ILSignUpLegalSheetViewController.swift` | Bundled terms and privacy text in a sheet; "Tôi đồng ý" ticks the box. | built — unchanged in v2.0 (one shared text deferred) |
| SignUp / Coordinator | `Presentation/Scenes/SignUp/ILSignUpCoordinator.swift` | Forwards nav events; presents AddTemple and the legal sheet; keeps the SignUp VC alive under Otp so "Đổi email" pops back to the filled form. | built |
| AddTemple | `Presentation/Scenes/AddTemple/*`, `Domain/UseCases/AddTemple/ILAddTempleUseCase.swift`, `Domain/Entities/ILTempleProposalEntity.swift` | Name, province and ward from the administrative-unit list, optional street line; returns an `ILTempleProposalEntity`. | built |
| Temple proposal / Data | `Data/DataSources/Remote/TempleSuggestionEndpoint.swift` (exists, unused), new `Domain/Repositories/ILTempleSuggestionRepository.swift` + `Data/Repositories/ILTempleSuggestionRepositoryImpl.swift` | `submit(_ proposal:)`, public (no token); errors swallowed and logged without personal data. | **planned** (criterion 19, closes TD-SignUp-002) |
| Otp / Entities | `Domain/Entities/ILOtpTimingEntity.swift`, `ILSignUpOTPEntity.swift` | `expiresInSeconds`, `resendAfterSeconds`. | built |
| Otp / UseCase | `Domain/UseCases/Otp/ILOtpUseCase.swift` | `verifyCode(email:code:)` (stores the session via the shared session store, then submits the kept proposal), `resendCode(email:)`; `ILOtpError`. | **change**: email instead of phone; drop `voiceCallUnsupported`; add `rateLimited`, `sendLimited(until:)`, `locked(until:)`, `pendingExpired` |
| Otp / Data | `Data/DTOs/ILOtpDTO.swift`, `Data/DTOs/Mappers/ILOtpMapper.swift`, `VerifyOTPEndpoint.swift`, `ResendOTPEndpoint.swift`, `Data/Repositories/ILOtpRepositoryImpl.swift` | Verify `{email, otp_code}`; resend `POST /v1/auth/register/resend-otp {email}`; user DTO `ordination_temple_id`. | **change**: bodies, resend path, drop `purpose`, user DTO field (closes TD-SignUp-004) |
| Otp / State + ViewModel | `Presentation/Scenes/Otp/ILOtpStateModel.swift`, `ILOtpViewModel.swift` | Two timers (validity countdown, resend wait), `isLockedUntil`, errors; `.didVerify`, `.changeEmail`, `.backToFormExpired`. | **change**: live validity countdown; lock state; expired → back to form |
| Otp / Views | `ILOtpViewController.swift`, `Views/ILOtpResendRowView.swift`, `Views/ILOtpVoiceCallBannerView.swift` | Subtitle with the email, "Đổi email", countdown text, resend row. | **change**: remove the voice-call banner view; copy |
| Otp / Coordinator | `Presentation/Scenes/Otp/ILOtpCoordinator.swift` | `didVerify` → `AppCoordinator.showMain()`; "Đổi email" and registration expired → pop to SignUp. | **change**: argument `email` |
| Session store (shared) | `Docs/Specs/Login/design.md` — `ILAuthSessionStore` | Saves tokens to the Keychain and the user to Core Data after verify or sign-in. | see Login |
| Strings | `Resources/Localization/vi.json` (+ `en.json` if present) | §3.1.1 copy: "Đăng ký", email hint, "Đổi email", "Gửi lại mã", expired/locked/rate-limited messages; remove SMS, voice-call, "Đổi số", email-taken strings. | **change** |
| Product vectors | `Scripts/sync-product-vectors.sh` (shared with Memorial), `InnerLampTests/ProductVectors/onboarding/`, `ILOnboardingProductVectorTests` | Runs every case of the four `rules/*.json` against `ILSignUpRules`. | **planned** |

## Navigation flow

```
AppCoordinator.start → Splash
  ├─ session stored              → showMain()
  ├─ intro not seen              → showOnboarding()
  │     ├─ "Bỏ qua" / "Tạo tài khoản"   (flag set) → showSignUp()
  │     └─ "Tôi đã có tài khoản"        (flag set) → showLogin()
  └─ intro seen, no session      → showLogin()   (root; "Tạo tài khoản mới" pushes SignUp)

SignUp
  ├─ "Đăng ký" ✓ → showOtp(email:, timing)   (pushed; SignUp stays underneath)
  ├─ link to Login → showLogin()
  ├─ terms links → ILSignUpLegalSheetViewController (bundled text, unchanged)
  └─ "Không tìm thấy chùa?" → AddTemple (modal) → proposal kept in SignUp state

Otp
  ├─ verified → showMain()
  └─ "Đổi email" / PENDING_REGISTRATION_EXPIRED → pop to SignUp (values kept)
```

## Step-by-step Flow — Registration

```
Step 1 — Submit the form
- Trigger: "Đăng ký", terms accepted, local checks of criterion 9 pass, no submit in flight.
- API: POST /v1/auth/register/request-otp (public)
    - Success 200 → ILSignUpOTPEntity {expiresInSeconds, resendAfterSeconds}; go to Step 2.
      The answer is the same for an email that already has an account (criterion 14).
    - 400 INVALID_* → error under the field; stay.
    - 409 PHONE_TAKEN → criterion 15; stay.
    - 429 OTP_RESEND_TOO_SOON / OTP_SEND_LIMITED / RATE_LIMITED → message with the wait or unlock time; stay.
    - 500 EMAIL_SEND_FAILED / 5xx / offline → generic or no-internet message; stay.

Step 2 — Show the code screen
- Effect: AppCoordinator.showOtp(email:, timing); both timers start from the response.

Step 3 — Resend (repeatable)
- Trigger: "Gửi lại mã" after the resend wait.
- API: POST /v1/auth/register/resend-otp {email}
    - Success → clear the entry, restart both timers from the response.
    - 429 OTP_RESEND_TOO_SOON → restart the resend timer from retry_after_seconds.
    - 429 OTP_SEND_LIMITED → unlock time; entry stays usable.
    - 400 PENDING_REGISTRATION_EXPIRED → Step 5.

Step 4 — Verify
- Trigger: 6 digits entered, "Xác nhận", entry not locked.
- API: POST /v1/auth/register/verify-otp {email, otp_code}
    - Success 201 → ILAuthSessionStore.save(session) (Keychain + user); go to Step 6.
      Storage failure → "Không lưu được phiên đăng nhập" (the account exists; the user can sign in).
    - 400 OTP_INVALID → wrong-code message, keep the entry.
    - 400 OTP_EXPIRED → expired message, emphasise resend.
    - 429 OTP_LOCKED → unlock time, entry disabled until locked_until.
    - 400 PENDING_REGISTRATION_EXPIRED → Step 5.
    - 409 PHONE_TAKEN (taken while pending) → back to SignUp with the phone error.

Step 5 — Registration expired
- Effect: message of FR-ONB-010; pop to SignUp with every value kept.

Step 6 — Send the temple proposal (only when one is kept)
- API: POST /v1/temple-suggestions (public, no token; live in backend temple-suggestion v3.4)
    - Any result → ignored for the user; Main opens either way.
- Effect: AppCoordinator.showMain().
```

## Deliberately stubbed for now

- The email-code routes exist only in the backend spec; until the backend ships them, iOS v2.0 can be
  built and unit-tested against mocks, and E2E waits for the backend (`innerlamp-be`
  `docs/specs/features/onboarding/tasks.md`).
