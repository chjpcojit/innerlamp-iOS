# Design — SignUp

Version: 1.13
Last updated: 2026-09-23
Status: in-progress — UI + local logic + API integration done; the OTP-timing
question is resolved and prose synced to the shipped call; manual real-backend
test pending (`tasks.md` Phase 3)

> See `changelog.md` in this folder for the version history of this spec.

## Overview

SignUp follows MVVM-C + Clean Architecture per `AGENTS.md` and
`Core/Base/README.md`, matching the canonical `Onboarding` feature shape.
It is a **cross-section navigation** (Onboarding → SignUp → OTP/Login), so
`ILSignUpCoordinator` is owned and wired by `AppCoordinator`, not by a
parent feature coordinator.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILSignUpEntity.swift` | Pure business fields only: `displayName`, `phoneNumber`, `ordinationPlace` (optional, added v1.6), `email` (required as of v1.6 — for donation receipts), `password`. No UI-only state. |
| Domain / UseCase | `Domain/UseCases/SignUp/ILSignUpUseCase.swift` | Validation rules (`validateDisplayName`/`validatePhoneNumber`/`validateEmail`/`validatePassword`, password minimum = 8 via `minimumPasswordLength`), dharma name suggestions, password strength scoring, `sendVerificationCode(displayName:ordinationPlace:phoneNumber:email:password:) async throws -> ILSignUpOTPEntity` — builds the `ILSignUpEntity` and delegates to the repository. Also owns `ILSignUpError`, the feature error type the repository maps `NetworkError` into. |
| Domain / Validation | `Domain/Validation/ILEmailValidator.swift` | Single source of truth for the email format regex (added v1.6) — used by `validateEmail` (submit-time) and `ILSignUpStateModel.isEmailFormatValid` (live feedback). Foundation only. |
| Domain / Entity | `Domain/Entities/ILSignUpOTPEntity.swift` | Metadata returned by a successful `request-otp`: `message`, `expiresInSeconds`, `resendAfterSeconds`. Carried from SignUp to the OTP screen so its countdown and expiry copy use the server's real values — the response-shape ⚠️ is resolved in favour of passing the timing through (v1.13). |
| Domain / Repository | `Domain/Repositories/ILSignUpRepository.swift` | Entity in / Entity out only: `requestRegistrationOTP(_ entity: ILSignUpEntity) async throws -> ILSignUpOTPEntity`. No DTO and no `NetworkError` may cross this line. |
| Data / Repository | `Data/Repositories/ILSignUpRepositoryImpl.swift` | The only place a DTO may exist above `NetworkService`: maps Entity → request DTO via `ILSignUpMapper`, calls `NetworkService`, maps the response DTO back, and converts `NetworkError` → `ILSignUpError`. Injected into `ILSignUpUseCaseImpl`. |
| Data / DTO | `Data/DTOs/ILSignUpDTO.swift` | `ILSignUpRequestOTPRequestDTO: Encodable` with explicit snake_case `CodingKeys` (`dharma_name`, `ordination_place`, `phone_number`, `email`, `password`) + `ILSignUpRequestOTPResponseDTO: Decodable` (`message`, `expiresInSeconds`, `resendAfterSeconds`) — no `CodingKeys` on the response, the shared decoder's `.convertFromSnakeCase` handles it. One type per wire shape. |
| Data / Mapper | `Data/DTOs/Mappers/ILSignUpMapper.swift` | `enum ILSignUpMapper` — static field-for-field `toDTO` / `toDomain`. Never touches `ILSignUpStateModel`. |
| Data / Endpoint | `Data/DataSources/Remote/RequestRegistrationOTPEndpoint.swift` | `POST /v1/auth/register/request-otp`, `requiresAuth = false` (public — no token regardless of Keychain state), JSON body from the request DTO. Unprefixed `<Action>Endpoint` types live under `Data/DataSources/Remote/`, per `il-data-layer-builder`'s placement rule (not `Core/Networking/`). |
| Presentation / State | `Presentation/Scenes/SignUp/ILSignUpStateModel.swift` | UI-only state: field errors (incl. `emailError`, `ordinationPlace` value), password strength, submitting flag, derived display values (`phoneE164`, `phoneHint`). No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/SignUp/ILSignUpViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILSignUpNavEvent` publisher. |
| Presentation / Coordinator | `Presentation/Scenes/SignUp/ILSignUpCoordinator.swift` | Pushes `ILSignUpViewController`; forwards nav events to `AppCoordinator` via `ILSignUpCoordinatorDelegate`. |
| Presentation / ViewController | `Presentation/Scenes/SignUp/ILSignUpViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped view | `Presentation/Scenes/SignUp/Views/ILDharmaNameSuggestionField.swift` | "Pháp danh" row — value + reroll button, content tied to SignUp's suggestion list. |
| New Design System components | `ILCheckboxRow`, `ILStrengthMeterView`, `ILPhoneField`, `ILCountryPickerViewController`, `ILCountry` model, `ILField.onTrailingTap` extension, `ILTypography.authTitle` token | Generic, reusable across auth screens (Login, ForgotPassword). |
| **Shared / pending** — Presentation | `Presentation/Common/LegalContent/ILLegalContentViewController.swift` (not yet created) | **Not implemented yet** — generic modal screen wrapping a `WKWebView`, initialized with a URL (no `ILLegalContentType` enum needed since it's just "load this URL"). Placed under `Common/` (not `Scenes/SignUp/`) since it must be reusable by Login/other auth screens later, per `references/naming_conventions.md` §3 shared-vs-feature-scoped rule. No Domain/UseCase/Repository — pure Presentation, content is a public URL. |
| **Modified** — Design System component | `ILCheckboxRow` | **Needs modification** (not yet done) — currently renders plain static text; must expose two tap targets (`onTermsTap` / `onPrivacyTap` closures) over the "Terms of Service" / "Privacy Policy" substrings without toggling the checkbox itself. |

## Navigation flow

```
AppCoordinator
  └─ showOnboarding() → OnboardingCoordinator
       (tap "Bắt đầu" / "Bỏ qua") → onboardingDidRequestSignup
       → AppCoordinator.showSignUp()
            ILSignUpCoordinator
              push ILSignUpViewController
              (tap "Gửi mã xác thực") → signUpDidRequestVerification(
                  phoneNumber:, otpExpiresInSeconds:, resendAfterSeconds:)
                → AppCoordinator.showOtp(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:)
              (tap "Tôi đã có tài khoản") → signUpDidRequestLogin
                → AppCoordinator.showLogin()
```

## Data flow (submit)

1. `ILSignUpViewController.handleSubmitTapped()` → `submitTappedSubject`.
2. `ILSignUpViewModel.handleSubmit()`:
   - Guard `!isSubmitting && didAcceptTerms`.
   - Validate `displayName` / `phoneNumber` / `email` / `password`
     synchronously via `useCase.validateXxx` (country-aware phone
     validation; email required + format; password ≥ 8). `ordinationPlace`
     is never validated.
   - On validation error → emit state with per-field errors, stop.
   - On valid → `isSubmitting = true`, emit loading state, spawn `Task`
     calling `useCase.sendVerificationCode(displayName:ordinationPlace:phoneNumber:email:password:)`
     with `currentState.phoneE164` (grouped, dial-code-prefixed) and the
     trimmed `ordinationPlace`/`email`.
   - Success → emit
     `.didRequestVerification(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:)`
     using the `ILSignUpOTPEntity` the repository returned.
   - Any failure — including `ILSignUpError.phoneAlreadyRegistered` — →
     set `submitError`, `isSubmitting = false`, stay on the SignUp screen
     and show the alert; **no navigation event is emitted** (reverted in
     v1.9; v1.8 had emitted `.goToLogin` here). `.goToLogin` is emitted
     only by the "Tôi đã có tài khoản" tap.

## Email field (required as of v1.6; added v1.5)

Design handoff's `InnerLamp Prototype.dc.html` block `isSignup` (and the
design handoff's own top-level `README.md`, screen `signup`) includes an
**Email** field between phone and password, used to receive donation
receipts — **not** an auth identifier (phone number remains the sole
login identifier). v1.5 added it back as optional to match the design's
`signupNext`; **v1.6 makes it required** on user request, deliberately
diverging from the design handoff (which is now out of date on this
point) and matching `Docs/Specs/API/openapi.yaml`
(`RequestOTPRequest.required: [email, password, phone_number]`):

- `ILSignUpUseCase.validateEmail` — runs on submit like the other
  fields: empty → `signup.error.emailRequired`, bad format →
  `signup.error.emailInvalid`. Result is stored on
  `ILSignUpStateModel.emailError`, which is part of `hasValidationError`,
  so a bad/empty email now **blocks** "Gửi mã xác thực".
- `ILSignUpStateModel.hasEmailValue` / `isEmailFormatValid` remain for
  live feedback while typing (error/success border only when non-empty).
  Both this and `validateEmail` delegate to `ILEmailValidator.isValid`
  so the regex lives in exactly one place. `emailError` takes priority
  over the live state in `ILSignUpViewController.updateUI`, and is
  cleared when the user edits the field.

## Ordination place field (optional, added v1.6)

New optional free-text field "Nơi xuất gia" placed right after the
dharma name. Maps to `ordination_place` (nullable) in
`RequestOTPRequest` / `User` in `Docs/Specs/API/openapi.yaml`.

- `ILSignUpEntity.ordinationPlace` (business field) and
  `ILSignUpStateModel.ordinationPlace` (raw input mirror).
- `ILSignUpViewModel.handleOrdinationPlaceChanged` only mirrors the text;
  no `validateOrdinationPlace` exists on purpose (any value, including
  empty, is valid). `handleSubmit` trims whitespace and passes it to
  `sendVerificationCode`.
- Return-key chain: dharma name → ordination place → phone → email →
  password.

Confirmed (2026-09-21): the field means the temple/monastery where the
user was ordained ("chùa / tịnh xá") and is optional — no design change
was needed, this is exactly how it is already built.

> ⚠️ Not confirmed: not in the design handoff — final copy and position
> of this field are unconfirmed (see `requirements.md`). The current
> Vietnamese strings and the position right after the dharma name are
> placeholders pending designer input.

## Password rule (v1.6)

Minimum length is 8 (`ILSignUpUseCaseImpl.minimumPasswordLength`),
up from 6, matching `RequestOTPRequest.password.minLength: 8` in the
OpenAPI contract. The same constant is the first threshold of
`passwordStrength(for:)`, so anything under 8 characters scores "weak".
Login (`ILLoginUseCase.validatePassword`) stays "non-empty only" by
design — enforcing a minimum at login would only lock out existing
accounts, and the server is the authority on credentials.
ForgotPassword has no password or email input (it only displays the
already-registered contact), so nothing changed there.

## Step-by-step Flow — Full Registration (SignUp → OTP)

This is the technical sequence behind the one-line user story in
`requirements.md`, spelling out every network call and its
success/failure branch so no step is silently assumed. Steps 1–2 belong
to this feature; steps 3–4 belong to the OTP feature and are kept here
only as a short cross-reference — the OTP feature now owns them in
`Docs/Specs/Otp/` (design + tasks). SignUp's own work is Step 1 only.

The registration contract is now confirmed — the speculative
`/auth/signup/send-code` + `/auth/signup/create-account` names from
v1.6 are dropped, and registration is **two server calls plus a shared
resend**:

| Route | Caller | Request | Success data | Confirmed failures |
|---|---|---|---|---|
| `POST /v1/auth/register/request-otp` | SignUp (this feature) | `dharma_name`, `ordination_place` (optional), `phone_number` (grouped display string; normalized to E.164 server-side), `email`, `password` | `message`, `expires_in_seconds` (90), `resend_after_seconds` (60) | `400` VALIDATION_ERROR / INVALID_EMAIL / INVALID_PHONE / INVALID_PASSWORD, `409` PHONE_TAKEN / EMAIL_TAKEN, `413` PAYLOAD_TOO_LARGE, `429` OTP_LOCKED / OTP_RESEND_TOO_SOON / OTP_SEND_LIMITED, `500` SMS_SEND_FAILED / INTERNAL_ERROR |
| `POST /v1/auth/register/verify-otp` | OTP feature (out of SignUp's scope) | `phone_number`, `otp_code` | `access_token`, `refresh_token`, `user` | `400` OTP_INVALID / OTP_EXPIRED / PENDING_REGISTRATION_EXPIRED, `409` PHONE_TAKEN / EMAIL_TAKEN, `413`, `429` OTP_LOCKED, `500` INTERNAL_ERROR |
| `POST /v1/auth/resend-otp` | OTP feature (out of SignUp's scope) | `phone_number`, `purpose` (`"register"`) | `message`, `expires_in_seconds`, `resend_after_seconds`, `resend_remaining` | `400` OTP_INVALID / PENDING_REGISTRATION_EXPIRED / UNSUPPORTED_OTP_PURPOSE, `413`, `429` OTP_LOCKED / OTP_RESEND_TOO_SOON / OTP_SEND_LIMITED, `500` SMS_SEND_FAILED / INTERNAL_ERROR |

Source: `Docs/Specs/API/openapi.yaml` v3.9. Every route is public
(`requiresAuth = false`) and speaks the standard `ApiResponse` envelope
(`{"success": true, "data": …}` / `{"success": false, "error":
{code, message, type}, "details"?}`), handled centrally by
`NetworkService` (see `Docs/Specs/Networking/design.md`). `error.code` is
the discriminator the repository maps; `details.locked_until` and
`details.retry_after_seconds` carry the lock/cooldown timing.
`NOT_FOUND` / `METHOD_NOT_ALLOWED` / the `OPTIONS` preflight are global,
not per-route.

**Account creation is not a separate call.** `request-otp` only writes
the payload to `pending_registration`; `verify-otp` creates `users` +
`user_sessions` and deletes `pending_registration` in one transaction,
returning the first session's tokens (AC1/AC2/AC3/AC7).

```
Step 1 — Submit SignUp form (this feature)
- Trigger: user taps "Gửi mã xác thực", local validation passes
- Pre-condition: displayName/phoneNumber/email/password pass
  useCase.validateXxx (client-side only; submit is also ignored while a
  request is already in flight)
- API: POST /v1/auth/register/request-otp
  Body (snake_case, explicit CodingKeys on the request DTO):
  dharma_name (= displayName), ordination_place (optional; empty string
  when the user left it blank), phone_number (grouped display string, e.g.
  "+84 912 345 678"), email, password (min 8). requiresAuth = false.
  Confirmed: the server checks phone/email uniqueness as part of handling
  this same call (no separate "check exists" call) and persists only to
  pending_registration — no users row yet.
    - Success (200) → data {message, expires_in_seconds: 90,
      resend_after_seconds: 60}; emit
      .didRequestVerification(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:),
      go to Step 2
    - Failure (409 PHONE_TAKEN) → set submitError to the phone-taken
      message, stay on the SignUp screen, no navigation
    - Failure (409 EMAIL_TAKEN) → set submitError to the email-taken
      message, stay
    - Failure (429 OTP_LOCKED / OTP_SEND_LIMITED) → set submitError to a
      locked/limited message (sending unlocks at details.locked_until), stay
    - Failure (429 OTP_RESEND_TOO_SOON) → set submitError to a
      "try again in N seconds" message (details.retry_after_seconds), stay
    - Failure (500 SMS_SEND_FAILED / INTERNAL_ERROR) → set submitError to
      the shared generic error, stay
    - Failure (400 VALIDATION_ERROR / INVALID_EMAIL / INVALID_PHONE /
      INVALID_PASSWORD, 413 PAYLOAD_TOO_LARGE) → set submitError to the
      error message for the named field, stay
    - Failure (transport: noInternetConnection / timeout) → set
      submitError to error.no_internet / a retry message, stay
    - In every failure case: isSubmitting = false, no navigation event

Step 2 — Navigate to OTP screen (this feature, boundary)
- Trigger: Step 1 success
- Effect: ILSignUpCoordinator forwards
  signUpDidRequestVerification(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:)
  to AppCoordinator.showOtp(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:)
  — SignUp's responsibility ends here.
  Confirmed (v1.13): the server's expires_in_seconds / resend_after_seconds
  ride along in this event, so the OTP screen seeds its countdown and
  expiry copy from the real values instead of its old hardcoded 60s
  cooldown / "Mã có hiệu lực trong 10 phút".

Step 3 — Verify OTP + create account (OTP feature — see Docs/Specs/Otp/design.md)
- API: POST /v1/auth/register/verify-otp (phone_number, otp_code)
  Success (201) creates users + user_sessions and deletes
  pending_registration in one transaction — there is no separate
  create-account call; the tokens are stored in the Keychain and the app
  navigates to Home.
  Full failure matrix (OTP_INVALID / OTP_EXPIRED /
  PENDING_REGISTRATION_EXPIRED / PHONE_TAKEN / EMAIL_TAKEN / OTP_LOCKED /
  INTERNAL_ERROR) is owned by the OTP spec, not duplicated here.

Step 4 — Resend OTP (OTP feature — see Docs/Specs/Otp/design.md)
- API: POST /v1/auth/resend-otp (phone_number, purpose = "register")
  Shared endpoint; US-001 implements only purpose "register". request-otp
  and resend-otp share one per-phone send counter. Full failure matrix
  owned by the OTP spec.
```

## Terms of Service / Privacy Policy screen (pending, not yet implemented)

Newly in-scope per `requirements.md` v1.2 (previously listed as
out-of-scope). Not part of the registration API sequence above — this is
a **side navigation branch** off the SignUp screen that does not affect
`ILSignUpStateModel` or the submit flow.

Content source resolved (v1.3): a **public URL loaded in a web view**
(`WKWebView`), not bundled static text and not a custom backend/CMS API
— so **no Domain layer (`Entity`/`UseCase`/`Repository`) is needed**,
this stays pure Presentation:

```
ILSignUpViewController
  (tap "Terms of Service" text inside ILCheckboxRow) → onTermsTap closure
  → ILSignUpCoordinator.presentLegalContent(.termsOfService)
       modally presents ILLegalContentViewController(url: <ToS URL>)
         - loading state while WKWebView loads
         - error/retry state on no-connection or load failure
           (per requirements.md acceptance criteria)
  (tap "Privacy Policy" text) → onPrivacyTap closure
  → ILSignUpCoordinator.presentLegalContent(.privacyPolicy)
       modally presents ILLegalContentViewController(url: <Privacy URL>)
  (dismiss) → back to ILSignUpViewController, no state change
```

⚠️ Chưa xác nhận: the actual URL string values for ToS/Privacy — see
`requirements.md` Pending section. `ILLegalContentViewController` should
take the URL as an init parameter (not hardcode it inline) so the real
values can be supplied without touching this screen's code once
provided.

## API integration (implemented)

`ILSignUpUseCaseImpl.sendVerificationCode` is a real call as of v1.13 —
the stub described in earlier versions is gone. The chain is:

```
ILSignUpViewModel.handleSubmit()
  → ILSignUpUseCaseImpl.sendVerificationCode(...)     (builds ILSignUpEntity)
  → ILSignUpRepositoryImpl.requestRegistrationOTP(_:) (Data layer)
      → ILSignUpMapper.toDTO(entity)                  → request DTO
      → NetworkService.request(endpoint: RequestRegistrationOTPEndpoint,
                               responseType: ILSignUpRequestOTPResponseDTO)
      → ILSignUpMapper.toDomain(response)             → ILSignUpOTPEntity
      catch NetworkError → ILSignUpError.from(_:)
  → .didRequestVerification(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:)
```

- **DTOs** — `ILSignUpRequestOTPRequestDTO` declares explicit snake_case
  `CodingKeys`; `ILSignUpRequestOTPResponseDTO` relies on the shared
  decoder's `.convertFromSnakeCase`. Two types, because the shared
  `JSONEncoder` has no key strategy while the decoder does.
- **Error mapping** — `ILSignUpError.from(_:)` (in
  `Data/Repositories/ILSignUpRepositoryImpl.swift`, extending the Domain
  error type) is exhaustive over `NetworkError` and reads
  `NetworkError.apiError(code:message:type:details:)`'s `code` as the
  discriminator: `PHONE_TAKEN` / `EMAIL_TAKEN` / `OTP_LOCKED` /
  `OTP_SEND_LIMITED` / `OTP_RESEND_TOO_SOON` / `SMS_SEND_FAILED` /
  the `VALIDATION_ERROR`-family → `invalidInput`, everything else →
  `.server`. The 429 timing comes from `details` (`locked_until`,
  `retry_after_seconds`), then `ILSignUpError` localizes it through the
  shared `ILUnlockTimeFormatter`. No `NetworkError` ever crosses into
  `Domain/` or `Presentation/`.
- **Timing passthrough** — the resolved ⚠️ (see `requirements.md` Open
  questions): `ILSignUpOTPEntity` exists and `sendVerificationCode`
  returns it instead of `Void`, so the OTP screen's countdown/expiry copy
  comes from the server (90s / 60s) rather than a hardcoded value.
- **DI** — `DIContainer.makeSignUpRepository()` builds
  `ILSignUpRepositoryImpl(networkService:)`; `makeSignUpUseCase()` injects
  it into `ILSignUpUseCaseImpl`.
- **Tests** — `ILSignUpRepositoryTests` covers the error mapping, the
  mapper, both wire shapes, and the endpoint; `ILSignUpViewModelTests`
  injects `MockILSignUpRepository` into the real `ILSignUpUseCaseImpl`,
  covering the success path and each mapped failure.

Account creation itself, and the verify/resend calls (Steps 3–4 of the
Step-by-step Flow), happen in the OTP feature — it has its own spec in
`Docs/Specs/Otp/`, so nothing about them is a pending task for SignUp.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
block `isSignup`. See `InnerLamp/Presentation/Scenes/SignUp/README.md` for
the full design-vs-implementation comparison table and changelog.
