# Requirements — SignUp

Version: 1.13
Last updated: 2026-09-23
Status: in-progress — UI, local logic and API integration done (Phase 3); the
OTP-timing ⚠️ is resolved and recorded under Open questions (resolved), and the
prose below now matches the shipped call. Only the manual real-backend test
pending (`tasks.md` Phase 3)
Feature folder: `InnerLamp/Presentation/Scenes/SignUp/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented SignUp
> feature, as a worked example of the requirements/design/tasks format —
> see `Docs/Specs/OKF.md` for why and when these files are created.

## User Story

As a new visitor coming from Onboarding, I want to create an account with
my dharma name (or nickname), an optional ordination place, phone
number, a required email, and a password of at least 8 characters, so
that I can receive an OTP and finish registering for InnerLamp — the
email lets me receive donation receipts later.

## Acceptance Criteria (EARS notation)

- WHEN the SignUp screen loads, THE SYSTEM SHALL pre-fill the display
  name field with the first suggested dharma name and show the submit
  button disabled until the terms checkbox is checked.
- WHEN the user taps "Gợi ý" (suggest), THE SYSTEM SHALL cycle through a
  fixed list of 10 dharma name suggestions; free-text input is not
  allowed for this field.
- WHEN the user taps the country flag/dial code, THE SYSTEM SHALL present
  a country picker (search + list of 12 countries); selecting a country
  SHALL update the dial code and the phone validity hint immediately.
- WHEN the user types a phone number, THE SYSTEM SHALL show a live valid/
  invalid hint based on the selected country's minimum national digit
  count (not hardcoded to Vietnam).
- WHEN the user types an ordination place (optional free-text field,
  "Nơi xuất gia", for monastics), THE SYSTEM SHALL accept any text
  (including empty) without showing an error, and SHALL NOT block
  submit on it. An empty value SHALL be sent as an empty string.

  > ⚠️ Not confirmed: the design handoff has no ordination-place field —
  > its final Vietnamese label/placeholder/hint and its position
  > (currently right after the dharma name, shown to everyone) are
  > unconfirmed — blocks final copy in `vi.json` and a design-accurate
  > layout. (Meaning and optionality are confirmed — see Open questions
  > (resolved).)
- WHEN the user types an email (required field, for donation receipts),
  THE SYSTEM SHALL show a live format hint only while the field is
  non-empty (error border when the format is invalid, success state when
  valid).
- WHEN the user types a password, THE SYSTEM SHALL show a live 3-segment
  strength meter (weak / fair / strong). A password shorter than 8
  characters SHALL be scored "weak".
- WHEN the user taps the terms checkbox, THE SYSTEM SHALL enable/disable
  the submit button accordingly.
- WHEN the user taps "Gửi mã xác thực" (submit) with invalid or missing
  fields — an empty or badly formatted email, a phone number below the
  selected country's minimum digit count, or a password shorter than 8
  characters — THE SYSTEM SHALL show an inline error per field and SHALL
  NOT call the backend. Email is required: empty shows "Vui lòng nhập
  email", a bad format shows "Email chưa đúng định dạng".
- WHEN the user taps submit with all fields valid, THE SYSTEM SHALL show
  a loading state and call `POST /v1/auth/register/request-otp`
  (`Docs/Specs/API/openapi.yaml` v3.9), then either:
  - on success (HTTP 200): navigate to the OTP screen carrying the phone
    number in E.164-like grouped format **plus** the server's
    `expires_in_seconds` / `resend_after_seconds` timing, which the OTP
    screen uses to seed its resend countdown and expiry copy, or
  - on failure: show an error and stay on the SignUp screen so the user
    can correct the input in place. No automatic navigation to Login
    happens on any failure (reverted in v1.9; v1.8 had redirected to
    Login here). The confirmed failure branches are:
    - the phone already has an account (`409 PHONE_TAKEN`) → show the
      "Số điện thoại này đã được đăng ký" alert;
    - the email already has an account, or is held by another phone's
      live pending registration (`409 EMAIL_TAKEN`) → show the
      email-already-registered alert;
    - the number is temporarily locked (`429 OTP_LOCKED`) or has hit the
      send cap (`429 OTP_SEND_LIMITED`) → show a locked/limited alert
      including when sending unlocks, from `details.locked_until`;
    - the resend cooldown has not elapsed (`429 OTP_RESEND_TOO_SOON`) →
      show a "please try again shortly" alert;
    - the OTP was persisted but the SMS provider refused the send
      (`500 SMS_SEND_FAILED`) or an infrastructure failure occurred
      (`500 INTERNAL_ERROR`) → show the shared generic error;
    - the request is rejected as malformed or format-invalid
      (`400 VALIDATION_ERROR` / `INVALID_EMAIL` / `INVALID_PHONE` /
      `INVALID_PASSWORD`, `413 PAYLOAD_TOO_LARGE`) → show the
      corresponding error message;
    - the device is offline or the request times out → show the shared
      no-internet / retry error.
- WHEN the form is submitted, THE SYSTEM SHALL send `phone_number` as the
  grouped, dial-code-prefixed display string the user sees
  (`+84 912 345 678`) — not a digit-only E.164 string. The contract
  normalizes any `IsValidPhone`-accepted shape to E.164 server-side
  (`Docs/Specs/API/openapi.yaml`, `RequestOTPRequest.phone_number`), so
  the display string and the stored value collide on the same account.
- WHEN the user taps submit while a submit request is already in flight,
  THE SYSTEM SHALL ignore the tap and SHALL NOT send the form twice.
- WHEN the user taps "Tôi đã có tài khoản" (I already have an account),
  THE SYSTEM SHALL navigate to the Login screen.
- WHEN the user taps back, THE SYSTEM SHALL return to Onboarding.
- WHEN the user taps "Terms of Service" within the checkbox row text,
  THE SYSTEM SHALL present a screen showing the Terms of Service
  content, without unchecking or otherwise affecting the checkbox state.
- WHEN the user taps "Privacy Policy" within the checkbox row text,
  THE SYSTEM SHALL present a screen showing the Privacy Policy content,
  without unchecking or otherwise affecting the checkbox state.
- WHEN the user dismisses the Terms of Service / Privacy Policy screen,
  THE SYSTEM SHALL return to the SignUp screen with all previously
  entered field values and checkbox state unchanged.
- WHEN the Terms of Service / Privacy Policy screen loads, THE SYSTEM
  SHALL load and display the content from a **public URL** (web page),
  not a locally-bundled static text or a custom backend/CMS API.
- WHEN the device has no internet connection or the URL fails to load,
  THE SYSTEM SHALL show an inline error/retry state on that screen
  instead of a blank page.

## Out of scope (this feature boundary, not backend work)

- Account creation itself — the account is created by the follow-on
  `POST /v1/auth/register/verify-otp` call, not by a separate
  create-account endpoint and not by SignUp. Owned by the OTP feature,
  which now has its own spec (`Docs/Specs/Otp/`), not SignUp.

## Pending (not yet implemented — see `tasks.md`)

- Manual end-to-end verification against a real/staging backend
  (`tasks.md` Phase 3, last item). The integration itself is built and
  covered by unit tests, but has not been exercised against a live server
  yet: success, `PHONE_TAKEN`, `EMAIL_TAKEN`, the 429 lock/cooldown/cap
  cases, and an offline/timeout run.

  > API integration is **done** as of v1.13: `sendVerificationCode` builds an
  > `ILSignUpEntity`, maps it via `ILSignUpMapper`, and calls
  > `POST /v1/auth/register/request-otp` (snake_case `dharma_name`,
  > `ordination_place` optional, `phone_number`, `email`, `password`)
  > through `ILSignUpRepositoryImpl`, which maps every `NetworkError` to an
  > `ILSignUpError` case. The server's `expires_in_seconds` /
  > `resend_after_seconds` ride along to the OTP screen. This call only
  > writes the server's `pending_registration` — the account is created by
  > the follow-on `POST /v1/auth/register/verify-otp`, owned by the OTP
  > feature (`Docs/Specs/Otp/`). There is no separate create-account call.

- Exact URL values for Terms of Service and Privacy Policy web pages.
  Content source itself is resolved (public URL, see Open questions
  below); only the concrete URL strings are still missing. Blocks
  `tasks.md` Phase 5 from being fully implementable.

> ⚠️ Chưa xác nhận: real ToS/Privacy URLs not yet provided by user —
> placeholder/mock URLs must not be silently invented in their place.

## Open questions (resolved during implementation)

- ~~Should the server's `expires_in_seconds` / `resend_after_seconds` be
  passed through to the OTP screen, or should the OTP screen keep its
  hardcoded "Mã có hiệu lực trong 10 phút" / 60s resend values?~~ →
  **Pass the timing through.** `ILSignUpOTPEntity` was created
  (`Domain/Entities/ILSignUpOTPEntity.swift`) and `sendVerificationCode`
  returns it instead of `Void`;
  `.didRequestVerification` / `ILSignUpCoordinatorDelegate` /
  `AppCoordinator.showOtp` now carry `otpExpiresInSeconds` +
  `resendAfterSeconds`, and the OTP screen seeds its countdown/expiry copy
  from them. Resolved 2026-09-23, while implementing the OTP feature
  (see `Docs/Specs/Otp/`), which needed the real values.
- ~~Is `phone_number` sent as a digit-only E.164 string?~~ → No: the
  client sends the grouped display string (`+84 912 345 678`) and the
  server normalizes any `IsValidPhone`-accepted shape to E.164
  (`RequestOTPRequest.phone_number`). Resolved 2026-09-23 by reading
  `Docs/Specs/API/openapi.yaml` v3.9 against
  `ILSignUpStateModel.phoneE164`.
- ~~Does `Docs/Specs/API/openapi.yaml`'s `/auth/register/request-otp`
  path/snake_case fields differ from the `/auth/signup/send-code` name
  this spec assumed?~~ → Resolved: the real route is
  `POST /v1/auth/register/request-otp`, body `dharma_name` /
  `ordination_place` (optional) / `phone_number` / `email` / `password`;
  a successful response carries
  `{message, expires_in_seconds: 90, resend_after_seconds: 60}`. The
  superseded `/auth/signup/send-code` name is dropped everywhere. Also
  confirmed: `verify-otp` creates the account in one transaction
  (`users` + `user_sessions`), so the previously-assumed separate
  `/auth/signup/create-account` call does not exist. Resolved 2026-09-22
  from `Docs/Specs/API/openapi.yaml` v3.9 (the v3.2 marker in `design.md`
  is now closed).
- ~~When the phone number is already registered, should the user stay on
  SignUp or go to Login?~~ → **Stay on SignUp** — show the
  "Số điện thoại này đã được đăng ký" alert and let the user correct the
  phone number in place; no automatic navigation to Login. `.goToLogin`
  is then emitted only by "Tôi đã có tài khoản"
  (`test_submitTapped_whenPhoneAlreadyRegistered_showsErrorAndStaysOnScreen`,
  `test_loginPromptTapped_firesGoToLoginEvent`). This reverses the
  v1.8 decision (which had redirected to Login) — resolved 2026-09-21
  (user: "chỉ cần hiện thông báo lỗi số điện thoại đã đăng ký cho đơn
  giản").
- ~~What is the "Nơi xuất gia" field, and is it required?~~ → It is the
  place where a monastic was ordained (a temple / monastery, "chùa /
  tịnh xá"), and it is **optional** — empty is valid and never blocks
  submit. Confirmed as-is by the user, so it matches the existing
  implementation and `ordination_place` (nullable) in
  `Docs/Specs/API/openapi.yaml`. Resolved 2026-09-21 (user).
- ~~Is the email field optional?~~ → No, required (empty or malformed
  email blocks submit). Reverses the v1.5 behavior, which had followed
  the design handoff's `signupNext` (gated only on the terms checkbox).
  Also matches `Docs/Specs/API/openapi.yaml`, where `RequestOTPRequest`
  lists `email` under `required`. Resolved 2026-09-21 (user request).
- ~~What is the minimum password length?~~ → 8 characters (was 6). Also
  matches `RequestOTPRequest.password.minLength: 8` in
  `Docs/Specs/API/openapi.yaml`. Resolved 2026-09-21 (user request).
  Login intentionally does **not** enforce a minimum — it only requires
  a non-empty password and lets the server judge credentials; ForgotPassword
  has no password input. Neither needed to change.

- ~~Is "phone already registered" returned by the same `send-code`
  endpoint, or a separate "check phone exists" API call made before
  it?~~ → Same endpoint — the server checks the phone as part of
  handling `request-otp` (the endpoint that replaced the working name
  `send-code`) and returns `409 PHONE_TAKEN` if it's already registered;
  no separate check-phone call. Resolved 2026-09-15; endpoint name
  re-confirmed 2026-09-22 against `Docs/Specs/API/openapi.yaml` v3.9.
- ~~Should phone validation be Vietnam-only?~~ → No, generalized per
  selected country's `nationalDigitCount`.
- ~~Is the dharma name field a free-text input?~~ → No, design shows a
  fixed suggestion list with a "reroll" button, not an `<input>`.
- ~~What is the content source for Terms of Service / Privacy Policy?~~
  → A public URL, loaded in a web view (not bundled static text, not a
  custom backend/CMS API). Resolved 2026-09-15.
