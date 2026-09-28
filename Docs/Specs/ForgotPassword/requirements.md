# Requirements — ForgotPassword

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — UI + local validation + navigation done; the reset
network call is a stub, and no reset API contract exists in the OpenAPI file
Feature folder: `InnerLamp/Presentation/Scenes/ForgotPassword/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented
> ForgotPassword feature. It documents what the shipped code actually does —
> including the one-line stub `sendResetInstructions` call — not an idealized
> version of it.

## User Story

As a user who forgot my password, I want to have reset instructions sent to my
registered phone number (or email), so that I can verify ownership and regain
access to my account.

## Acceptance Criteria (EARS notation)

- WHEN the ForgotPassword screen loads, THE SYSTEM SHALL show a title/subtitle
  and an empty phone field (country flag + dial code + national number, default
  country selected); the submit button SHALL be disabled until a valid contact
  is entered.
- WHEN the user taps the country flag/dial code, THE SYSTEM SHALL present the
  shared country picker (search + list of 12 countries); selecting a country
  SHALL update the dial code while preserving the already-typed national
  number.
- WHEN the user types a phone number, THE SYSTEM SHALL rebuild the full phone
  value from the selected dial code + typed digits, show a validity tick when
  the digit count meets the country's minimum, and enable the submit button.
- WHEN the user taps "Gửi hướng dẫn" (submit) with a valid phone number, THE
  SYSTEM SHALL show a loading state and call the reset-instructions use case,
  then either:
  - on success (phone method): navigate to the OTP screen carrying the phone
    number, or
  - on success (email method): emit an email-reset event, or
  - on failure: show the returned error message and stay on the screen, with no
    navigation event emitted.
- WHEN a reset request is already in flight, THE SYSTEM SHALL ignore a second
  tap on the submit button and SHALL NOT submit twice.
- WHEN the user taps the back control or "Trở lại đăng nhập" (back to login),
  THE SYSTEM SHALL return to the Login screen.
- WHEN the phone method is selected, THE SYSTEM SHALL use the phone number as
  the reset contact; when the email method is selected, THE SYSTEM SHALL use
  the email address as the reset contact.

## Out of scope (this feature boundary, not backend work)

- Password reset verification itself (the OTP entry, and any "choose a new
  password" step) — the phone path is currently delegated to the existing OTP
  feature (`Docs/Specs/Otp/`), which today only implements post-registration
  `verify-otp`, not a reset flow. Owned by the OTP feature / a future reset
  flow, not ForgotPassword.
- Email-based reset verification — there is no email-verification screen
  (`.didRequestEmailReset` currently reaches a `print` in `AppCoordinator`).

## Pending (not yet implemented — see `tasks.md`)

- The real `sendResetInstructions` network call. `ILForgotPasswordUseCaseImpl.
  sendResetInstructions` is `print("TODO: …")`, so the submit button **always
  succeeds** at runtime. There is no `ILForgotPasswordRepository` protocol and
  no Data-layer implementation yet. (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: the forgot-password API contract — no reset endpoint
  > exists in `Docs/Specs/API/openapi.yaml` v3.9 (the only auth paths are
  > `register/request-otp`, `register/verify-otp`, `resend-otp`, `login`,
  > `refresh`, `logout`). The `ResendOTPRequest.purpose` enum lists
  > `reset_password`, but the note says "US-001 only implements register; the
  > other three return UNSUPPORTED_OTP_PURPOSE". Blocks `tasks.md` Phase 3.

- Pre-filling the registered contact. `getInitialState()` returns an empty
  entity (it no longer reads Keychain — that was a local Repository call, out
  of scope). As a result the field starts empty and the user types the contact
  manually. (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: whether the app should pre-fill the registered phone
  > number/email from a future Auth API, or keep requiring manual entry —
  > affects whether `getInitialState()` stays empty.

## Open questions (resolved during implementation)

- ~~Is there a phone/email method switcher on the UI?~~ → No, not in the shipped
  UI. The design handoff's `isForgot` block (`resetWays`) has two option cards,
  but `ILForgotPasswordViewController` removed the switcher and always uses the
  phone method (`methodChanged` is bound to `Empty`). The StateModel/ViewModel
  still support `.email` (and tests cover it), but the live UI only reaches the
  phone path. Resolved during implementation (see
  `Presentation/Scenes/ForgotPassword/README.md`).
- ~~Should the phone reset path reuse the existing OTP screen?~~ → Yes, as a
  stopgap. `forgotPasswordDidRequestOtp` reuses `AppCoordinator.showOtp` with
  the default timing (`ILOtpStateModel.defaultOTPExpirySeconds` /
  `defaultResendCooldownSeconds`). This reuses the post-registration OTP flow
  for a reset purpose it does not yet distinguish. Resolved during
  implementation; the semantic mismatch is tracked under Pending.
