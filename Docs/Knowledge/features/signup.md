---
type: Feature
title: Sign Up
description: New-user registration screen — collects dharma name/nickname, optional ordination place, phone number, required email, and a password of at least 8 characters, then requests an OTP verification code.
resource: InnerLamp/Presentation/Scenes/SignUp/
tags: [auth, onboarding, mvvm-c]
status: draft
generated: { by: claude-code, at: 2026-09-23T01:16:39+07:00 }
sources:
  - path: Docs/Specs/SignUp/requirements.md
    kind: spec
  - path: Docs/Specs/SignUp/design.md
    kind: spec
  - path: InnerLamp/Presentation/Scenes/SignUp/README.md
    kind: implementation-notes
  - path: InnerLamp/Domain/UseCases/SignUp/ILSignUpUseCase.swift
    kind: code
  - path: InnerLamp/Data/Repositories/ILSignUpRepositoryImpl.swift
    kind: code
  - path: InnerLamp/Data/DataSources/Remote/RequestRegistrationOTPEndpoint.swift
    kind: code
---

# Summary

SignUp is the account-creation entry point reached from Onboarding. The
user provides a dharma name (chosen from a fixed suggestion list, not
free text), an optional ordination place (the temple / monastery where a
monastic was ordained — "chùa / tịnh xá"), a phone number (with
country/dial-code picker), a **required** email (for donation receipts,
not a login identifier), and a password of **at least 8 characters**,
then taps "Gửi mã xác thực" to request an OTP. On success the app
navigates to the OTP screen with the phone number in grouped
international format **and** the server's real
`expires_in_seconds` / `resend_after_seconds`, which seed that screen's
countdown and expiry copy. On any failure — including the phone or email
already being registered — the ViewModel shows an alert and the user
stays on the screen to correct the input in place; no path navigates to
Login automatically (only the explicit "Tôi đã có tài khoản" button
does).

**Current limitation**: the `POST /v1/auth/register/request-otp` call is
real and unit-tested, but has not yet been exercised against a
real/staging backend — see [Pending work](#pending-work) below.

# Architecture

MVVM-C + Clean Architecture, matching the canonical `Onboarding` shape
(see `InnerLamp/Core/Base/README.md`). Cross-section navigation
(Onboarding → SignUp → OTP/Login), so `ILSignUpCoordinator` is owned and
wired by `AppCoordinator`, not by a parent feature coordinator.

| Layer | Type | File |
|---|---|---|
| Domain / Entity | Domain Entity | `Domain/Entities/ILSignUpEntity.swift` — pure business fields only (`displayName`, `ordinationPlace`, `phoneNumber`, `email`, `password`) |
| Domain / Entity | Domain Entity | `Domain/Entities/ILSignUpOTPEntity.swift` — the `request-otp` response metadata (`message`, `expiresInSeconds`, `resendAfterSeconds`) carried to the OTP screen |
| Domain / UseCase | UseCase | `Domain/UseCases/SignUp/ILSignUpUseCase.swift` — validation (`validateDisplayName` / `validatePhoneNumber` / `validateEmail` / `validatePassword`), dharma name suggestions, password strength, `sendVerificationCode(displayName:ordinationPlace:phoneNumber:email:password:) async throws -> ILSignUpOTPEntity`; owns `ILSignUpError` |
| Domain / Validation | Validator | `Domain/Validation/ILEmailValidator.swift` — the single email-format regex, shared by `validateEmail` (submit-time) and `ILSignUpStateModel.isEmailFormatValid` (live feedback) |
| Domain / Validation | Formatter | `Domain/Validation/ILUnlockTimeFormatter.swift` — turns the 429 `locked_until` timestamp into the localized "try again after …" copy used by `ILSignUpError` |
| Domain / Repository | Repository protocol | `Domain/Repositories/ILSignUpRepository.swift` — `requestRegistrationOTP(_ entity: ILSignUpEntity) async throws -> ILSignUpOTPEntity`; Entity in / Entity out, no DTO or `NetworkError` crosses it |
| Data / Repository | Repository impl | `Data/Repositories/ILSignUpRepositoryImpl.swift` — maps Entity → DTO, calls `NetworkService`, maps the response back, converts `NetworkError` → `ILSignUpError` |
| Data / DTO | DTO | `Data/DTOs/ILSignUpDTO.swift` — `ILSignUpRequestOTPRequestDTO` (explicit snake_case `CodingKeys`) + `ILSignUpRequestOTPResponseDTO` (relies on `.convertFromSnakeCase`) |
| Data / Mapper | Mapper | `Data/DTOs/Mappers/ILSignUpMapper.swift` — static `toDTO` / `toDomain`, never touches `ILSignUpStateModel` |
| Data / Endpoint | Endpoint | `Data/DataSources/Remote/RequestRegistrationOTPEndpoint.swift` — `POST /v1/auth/register/request-otp`, `requiresAuth = false` |
| Presentation / State | State Model | `Presentation/Scenes/SignUp/ILSignUpStateModel.swift` — UI-only state (field errors incl. `emailError`, raw `ordinationPlace`, strength, `isSubmitting`, `phoneE164`), no UIKit import |
| Presentation / ViewModel | ViewModel | `Presentation/Scenes/SignUp/ILSignUpViewModel.swift` — `Input -> Output` per `ViewModelType`, exposes `navigationEventPublisher` |
| Presentation / Coordinator | Coordinator | `Presentation/Scenes/SignUp/ILSignUpCoordinator.swift` |
| Presentation / ViewController | ViewController | `Presentation/Scenes/SignUp/ILSignUpViewController.swift` |
| Feature-scoped view | View | `Presentation/Scenes/SignUp/Views/ILDharmaNameSuggestionField.swift` — value + "Gợi ý" reroll row |
| Tests | Unit tests | `InnerLampTests/ILSignUpViewModelTests.swift` (drives the real `ILSignUpUseCaseImpl` over a `MockILSignUpRepository`), `InnerLampTests/ILSignUpRepositoryTests.swift` (mapper, wire shapes, error mapping, endpoint), `InnerLampTests/ILEmailValidatorTests.swift` |

Field order on screen: dharma name → ordination place → phone → email →
password (strength meter) → terms checkbox. The keyboard return key walks
the same order; return on the password field submits.

Design System components introduced by this feature (each deserves its own
concept under `design-system/`, none written yet): `ILCheckboxRow`,
`ILStrengthMeterView`, `ILPhoneField`, `ILCountryPickerViewController`,
`ILCountry`, `ILField.onTrailingTap`, `ILTypography.authTitle`. Login
reuses all of them.

# Navigation

```
AppCoordinator
  └─ showOnboarding() → OnboardingCoordinator
       (tap "Bắt đầu" / "Bỏ qua") → onboardingDidRequestSignup
       → AppCoordinator.showSignUp()
            ILSignUpCoordinator
              push ILSignUpViewController
              (tap "Gửi mã xác thực", success) → signUpDidRequestVerification(phoneNumber:, otpExpiresInSeconds:, resendAfterSeconds:)
                → AppCoordinator.showOtp(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:)
              (tap "Tôi đã có tài khoản") → signUpDidRequestLogin → AppCoordinator.showLogin()
              (tap back) → popViewController + finish()
```

`AppCoordinator` does **not** `finish()` `ILSignUpCoordinator` on the OTP
branch (deliberate — the SignUp view controller is still on the stack
underneath, so its back / "Tôi đã có tài khoản" buttons must keep
working).

# Validation rules

Validation runs once, when the user taps "Gửi mã xác thực" (and only if
the terms checkbox is ticked), not per keystroke — except for the live
hints noted below. Any error blocks the call to `sendVerificationCode`.

- Display name: required (non-empty after trimming); chosen only from
  `ILSignUpUseCase.dharmaNameSuggestions` (10 fixed values) via the
  "Gợi ý" reroll button, no free text.
- Ordination place: **optional**, free text. Never validated and never
  blocks submit; an empty value is sent as an empty string, non-empty
  values are trimmed. There is deliberately no `validateOrdinationPlace`.
- Phone number: required; valid when the national digit count is within
  the selected country's `nationalDigitRange` (generalized per country,
  not hardcoded to Vietnam). `nationalDigits` drops a leading `0`, so
  `0912…` and `912…` are the same number.
- Email: **required**. Empty → `signup.error.emailRequired`
  ("Vui lòng nhập email"); bad format → `signup.error.emailInvalid`
  ("Email chưa đúng định dạng"). While typing, the field shows an
  error/success border only when non-empty; a submit-time `emailError`
  takes priority and is cleared when the user edits the field.
- Password: required, minimum **8** characters
  (`ILSignUpUseCaseImpl.minimumPasswordLength`; message
  `signup.error.passwordTooShort`). The strength meter (weak / fair /
  strong) is derived live from length (≥ 8, ≥ 10) + digit/symbol
  presence, purely for UI feedback — anything under 8 characters scores
  "weak". Login does not enforce a minimum (non-empty only).
- Terms checkbox: `ILSignUpStateModel.isSubmitEnabled` is
  `didAcceptTerms && !isSubmitting`, so the CTA stays disabled until the
  checkbox is ticked.

# Submit flow and error mapping

`handleSubmit()` spawns a `Task` and calls
`useCase.sendVerificationCode(...)` with `currentState.phoneE164` (the
grouped, dial-code-prefixed display string — e.g. `+84 912 345 678`, not
a digit-only E.164 string; the server normalizes any accepted shape) and
the trimmed `ordinationPlace` / `email`. The chain is:

```
ILSignUpViewModel
  → ILSignUpUseCaseImpl.sendVerificationCode(...)      (builds ILSignUpEntity)
  → ILSignUpRepositoryImpl.requestRegistrationOTP(_:)  (Data layer)
      → ILSignUpMapper.toDTO → ILSignUpRequestOTPRequestDTO
      → NetworkService.request(endpoint: RequestRegistrationOTPEndpoint,
                               responseType: ILSignUpRequestOTPResponseDTO)
      → ILSignUpMapper.toDomain → ILSignUpOTPEntity
      catch NetworkError → ILSignUpError.from(_:)
  → .didRequestVerification(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:)
```

`ILSignUpError.from(_:)` is exhaustive over `NetworkError` and
discriminates on the envelope's `error.code` (never the human-readable
message), with the 429 timing read from `error.details`:

| Server (`error.code`) | `ILSignUpError` | Copy |
|---|---|---|
| `PHONE_TAKEN` | `.phoneAlreadyRegistered` | `signup.error.phoneTaken` |
| `EMAIL_TAKEN` | `.emailTaken` | `signup.error.emailTaken` |
| `OTP_LOCKED` | `.otpLocked(lockedUntil:)` | `signup.error.otpLocked(Until)` |
| `OTP_SEND_LIMITED` | `.otpSendLimited(lockedUntil:)` | `signup.error.otpSendLimited(Until)` |
| `OTP_RESEND_TOO_SOON` | `.otpResendTooSoon(retryAfterSeconds:)` | `signup.error.otpResendTooSoon(Seconds)` |
| `SMS_SEND_FAILED` | `.smsSendFailed` | `signup.error.smsSendFailed` |
| `VALIDATION_ERROR` / `INVALID_EMAIL` / `INVALID_PHONE` / `INVALID_PASSWORD` / `PAYLOAD_TOO_LARGE` | `.invalidInput` | `signup.error.invalidInput` |
| — (transport) | `.networkUnavailable` / `.timedOut` | `error.no_internet` / `signup.error.timedOut` |
| anything else | `.server` | `error.generic` |

Every case ends the same way: `isSubmitting = false`, `submitError` set,
no navigation event, user stays on the screen. `phoneAlreadyRegistered`
is **not** special-cased into a Login redirect.

# Pending work

- The integration has not been exercised against a real/staging backend.
  `Docs/Specs/SignUp/tasks.md` Phase 3 keeps exactly one unchecked item:
  run success, `PHONE_TAKEN`, `EMAIL_TAKEN`, the 429 lock/cooldown/cap
  cases, and an offline/timeout run against a live server.
- The Terms of Service / Privacy Policy links inside the checkbox row are
  static text, not tappable
  (`ILSignUpViewController.termsRow` wires only `onToggle`). Implementing
  them needs: `ILCheckboxRow` tap regions over the two substrings, an
  `ILLegalContentViewController` (`Presentation/Common/`,
  `WKWebView` + loading/error-retry state), a
  `presentLegalContent(url:)` method on `ILSignUpCoordinator`, and the two
  real URLs — **the real URLs have not been provided**, so no placeholder
  may be invented (`Docs/Specs/SignUp/tasks.md` Phase 5).
- Final copy and position of the ordination-place field are unconfirmed —
  the design handoff has no such field, so the current Vietnamese strings
  (`signup.field.ordinationPlace.*` in
  `InnerLamp/Resources/Localization/vi.json`) and its position right after
  the dharma name are placeholders pending the designer.
- Promote this concept to `stable` once the end-to-end flow has been
  verified against a real/staging backend (same trigger as the spec's
  `status`).

# Known gaps vs. design

- The design handoff (`InnerLamp Prototype.dc.html`, block `isSignup`)
  treats email as optional and has no ordination-place field; the
  implementation intentionally diverges on both (email required by user
  request and by the API contract, which lists it under `required`).
- The "Terms of Service" / "Privacy Policy" links are rendered as plain
  text rather than tappable links — see Pending work.

# Related concepts

- [Login](login.md) (`InnerLamp/Presentation/Scenes/Login/`) — reachable
  via "Tôi đã có tài khoản"; Login reuses this feature's
  `ILPhoneField` / `ILCountryPickerViewController` and the same
  phone-number formatting rules. Login does not enforce a minimum
  password length.
- OTP feature (`InnerLamp/Presentation/Scenes/Otp/`) — receives the phone
  number plus the server's timing after a successful verification-code
  request, verifies the code, creates the account, and stores the
  session. It has a spec (`Docs/Specs/Otp/`) but **is not yet documented
  as an OKF concept in this bundle**.
- [Sign Up spec](../../Specs/SignUp/requirements.md) — the work-order spec
  this concept was reconciled against (`Docs/Specs/SignUp/`, v1.13).
- `request-otp` endpoint concept
  (`Docs/Knowledge/api/auth-signup.md`) — **not yet written**; the
  request/response shapes are documented here and in
  `Docs/Specs/SignUp/design.md` instead.
