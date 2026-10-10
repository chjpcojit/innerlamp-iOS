# Tasks — SignUp

Version: 1.13
Last updated: 2026-09-23
Status: in-progress (Phase 3 done bar the manual real-backend test; the OTP
timing ⚠️ is resolved — SignUp passes the server's `expires_in_seconds` /
`resend_after_seconds` through to the OTP screen, which now has its own spec in
`Docs/Specs/Otp/`)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature was built UI-first, then Domain/logic filled in with
> a stubbed backend call, matching the project's preferred workflow (see
> `Docs/Specs/OKF.md` §3 discussion on UI-first task ordering). Checked
> items below reflect what shipped so far; unchecked items are real
> pending work, not hypothetical examples.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILSignUpViewController` extending `BaseViewController`
- [x] `setupViews()`: add `ILDharmaNameSuggestionField`, `ILPhoneField`,
      ordination-place `ILField` (optional, added v1.6), email `ILField`
      (required as of v1.6, live format feedback + submit-time error),
      password `ILField` (secure + `onTrailingTap`), `ILStrengthMeterView`,
      `ILCheckboxRow`, submit `ILButton`, footer container
- [x] `setupConstraints()`: pin footer to `keyboardLayoutGuide`, scroll
      area above it, per design handoff spacing/typography tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state` via `updateUI(with:)`
- [x] Add new generic Design System components required by this screen:
      `ILCheckboxRow`, `ILStrengthMeterView`, `ILPhoneField`,
      `ILCountryPickerViewController`, `ILCountry`, `ILField.onTrailingTap`,
      `ILTypography.authTitle`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (block `isSignup`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILSignUpEntity` (pure business fields only, incl. `email`
      — required as of v1.6 — and optional `ordinationPlace`, added v1.6)
- [x] Create `ILSignUpStateModel` + `ILPasswordStrength` (Presentation-side
      UI state, no UIKit import)
- [x] Create `ILSignUpUseCase` / `ILSignUpUseCaseImpl`:
      - dharma name suggestion list
      - `validateDisplayName` / `validatePhoneNumber` / `validateEmail` /
        `validatePassword` (minimum 8 characters, v1.6)
      - `passwordStrength(for:)`
      - `sendVerificationCode` — builds the `ILSignUpEntity` and validates
        the form's shape; the repository call itself lands in Phase 3
- [x] Create `Domain/Validation/ILEmailValidator.swift` — single email
      regex shared by `validateEmail` and `ILSignUpStateModel.isEmailFormatValid`
      (v1.6), tested by `InnerLampTests/ILEmailValidatorTests.swift`
- [x] Create `ILSignUpViewModel` (`Input -> Output`, `ILSignUpNavEvent`)
- [x] Create `ILSignUpCoordinator` + `ILSignUpCoordinatorDelegate`
- [x] Wire `DIContainer.makeSignUpUseCase/ViewModel/Coordinator`
- [x] Wire `AppCoordinator.showSignUp()` + conform to
      `ILSignUpCoordinatorDelegate`
- [x] Unit tests: `InnerLampTests/ILSignUpViewModelTests.swift` (22 tests,
      driven via `Input` publishers) — originally against a manual
      `MockILSignUpUseCase`; reworked in Phase 3 to inject
      `MockILSignUpRepository` into the real `ILSignUpUseCaseImpl`

## Phase 3 — API integration (done; only the manual real-backend test left)

> Contract confirmed (`Docs/Specs/API/openapi.yaml` v3.9): the SignUp
> call is `POST /v1/auth/register/request-otp` — request
> `dharma_name` (= `displayName`), `ordination_place` (optional; empty
> string allowed), `phone_number` (the grouped display string; the
> contract normalizes any `IsValidPhone` shape to E.164 server-side),
> `email`, `password` (min 8); response `data` = `{message,
> expires_in_seconds: 90, resend_after_seconds: 60}`. Public
> (`requiresAuth = false`). Account creation is **not** here — it happens
> in the follow-on `verify-otp` call, owned by the OTP feature
> (`Docs/Specs/Otp/`).

- [x] Create `ILSignUpRequestOTPRequestDTO` (`Encodable`, explicit
      snake_case `CodingKeys`) + `ILSignUpRequestOTPResponseDTO`
      (`Decodable`) in `Data/DTOs/ILSignUpDTO.swift` — one type per wire
      shape, per the contract above
- [x] Create `ILSignUpMapper` (`Data/DTOs/Mappers/`) — Entity ↔ DTO only,
      never touches `ILSignUpStateModel`
- [x] Create `RequestRegistrationOTPEndpoint` (`Data/DataSources/Remote/`),
      unprefixed `<Action>Endpoint` name, `POST /v1/auth/register/request-otp`,
      `requiresAuth = false`, body from the request DTO — **not**
      `Core/Networking/` (corrected; see `design.md` Layers table)
- [x] Create `ILSignUpRepository` protocol (`Domain/Repositories/`) +
      `ILSignUpRepositoryImpl` (`Data/Repositories/`) wrapping
      `NetworkService`; Entity in / Entity out, converts `NetworkError`
      → `ILSignUpError` at the boundary
- [x] Extend `ILSignUpError` (`Domain/UseCases/SignUp/ILSignUpUseCase.swift`)
      with the contract's failure cases — `.emailTaken`, `.otpLocked`,
      `.otpSendLimited`, `.otpResendTooSoon`, `.smsSendFailed`, `.server`,
      `.networkUnavailable`, `.timedOut` (alongside the pre-existing
      `.phoneAlreadyRegistered`); added the matching `signup.error.*` keys
      to `vi.json`, reusing `error.generic` / `error.no_internet` for the
      shared cases
- [x] Add `ILSignUpError.from(_ error: NetworkError)` — exhaustive over
      `NetworkError`, reading `NetworkError.apiError(code:message:type:details:)`
      to discriminate `PHONE_TAKEN` / `EMAIL_TAKEN` / `OTP_LOCKED` /
      `OTP_SEND_LIMITED` / `OTP_RESEND_TOO_SOON` / `SMS_SEND_FAILED`
      (never pattern-match the human-readable message); the 429 timing is
      read from `details`
- [x] Resolve the ⚠️ in `requirements.md` Pending (pass
      `expires_in_seconds`/`resend_after_seconds` through
      `.didRequestVerification`, or keep the OTP screen's hardcoded
      values) — this decides whether `ILSignUpOTPEntity` is created and
      whether `sendVerificationCode` stops returning `Void`
- [x] Inject `ILSignUpRepository` into `ILSignUpUseCaseImpl.init` and
      replace the `sendVerificationCode` stub body with the real call
- [x] Wire `makeSignUpRepository()` (and the UseCase's new constructor
      arg) in `DIContainer`
- [x] Update `ILSignUpViewModelTests` + add `MockILSignUpRepository`
      (appended to the same test file per project convention) to cover the
      real success path and the mapped failure cases — the double now
      replaces `ILSignUpRepository` and the tests run the real
      `ILSignUpUseCaseImpl` on top of it; `ILSignUpRepositoryTests` covers
      the error mapping / mapper / wire shapes separately
- [ ] Manual test against a real/staging backend once available —
      success, PHONE_TAKEN, EMAIL_TAKEN, the 429 lock/cooldown cases, and
      an offline/timeout run

## Phase 4 — Documentation

- [x] `InnerLamp/Presentation/Scenes/SignUp/README.md` (implementation
      notes, design comparison table, changelog)
- [ ] `Docs/Knowledge/features/signup.md` (OKF concept) — the blocking
      condition is now cleared (Phase 3 landed), so this can be written:
      the existing file is **stale**, still describing
      `sendVerificationCode` as a `print("TODO: …")` stub and claiming no
      DTO/Mapper/Endpoint/Repository exist. Rewrite it via `okf-writer`
      (this skill does not write to `Docs/Knowledge/`), and reconcile its
      "on PHONE_TAKEN the ViewModel navigates to Login" statement with the
      shipped behavior (it sets `submitError` and stays on the screen)

## Phase 5 — Terms of Service / Privacy Policy screen (pending, new scope per requirements v1.2)

> Moved out of "Deferred" — this is now confirmed in-scope for SignUp,
> not a separate feature. All items below are unimplemented.

- [ ] Get real ToS/Privacy Policy URL values from user/stakeholder — see
      ⚠️ open item in `requirements.md` Pending section. Blocks the two
      tasks below; do not use placeholder URLs in their place
- [ ] Modify `ILCheckboxRow` to expose `onTermsTap` / `onPrivacyTap`
      closures over the respective substrings, without toggling the
      checkbox state
- [ ] Create `ILLegalContentViewController` (`Presentation/Common/LegalContent/`)
      wrapping `WKWebView`, initialized with a URL parameter (not
      hardcoded) — plus loading state and an error/retry state for
      no-connection or load failure
- [ ] Add `presentLegalContent(url:)` to `ILSignUpCoordinator` (modal
      presentation, not push — per `references/coordinator_navigation_rules.md`)
- [ ] Wire `ILSignUpViewController`'s new closures to
      `ILSignUpViewModel`/`ILSignUpCoordinator` per existing Input/Output
      pattern
- [ ] Unit test: tapping each link triggers the correct
      `presentLegalContent(url:)` call with the right URL, checkbox
      state unchanged
- [ ] Update `InnerLamp/Presentation/Scenes/SignUp/README.md` changelog
      once implemented

## Moved out — owned by the OTP feature (`Docs/Specs/Otp/`)

The registration flow's Steps 3–4 (`design.md` Step-by-step Flow) belong
to the OTP feature, **not** SignUp. They were listed here in earlier
versions because the OTP feature had no spec; it now has one
(`Docs/Specs/Otp/requirements.md`, `design.md`, `tasks.md`, `changelog.md`)
and the work has landed in code, so those items were removed from this
file rather than duplicated:

- `POST /v1/auth/register/verify-otp` + `POST /v1/auth/resend-otp` — the
  endpoints (`VerifyRegistrationOTPEndpoint`, `ResendOTPEndpoint`), DTOs,
  `ILOtpMapper`, `ILOtpRepository` / `ILOtpRepositoryImpl`, the
  `ILOtpError` mapping, and the Keychain session persistence are all
  implemented and tracked in `Docs/Specs/Otp/tasks.md` Phase 3 (only that
  spec's manual real-backend test remains `[ ]`).
- The OTP screen's timing copy is reconciled with the server's 90s / 60s
  values (this is the same decision that resolved SignUp's timing ⚠️ —
  see `requirements.md` Open questions).

Nothing in this section is pending work for SignUp.
