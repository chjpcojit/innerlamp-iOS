# Requirements — Login

Version: 1.1
Last updated: 2026-09-27
Status: in-progress — UI + local validation + navigation done; login contract
confirmed (`POST /v1/auth/login`), Data layer not yet implemented (stub)
Feature folder: `InnerLamp/Presentation/Scenes/Login/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Login
> feature. It documents what the shipped code actually does — including the
> one-line stub `login` call — not an idealized version of it.

## User Story

As a returning user (or a visitor coming from Onboarding / SignUp), I want
to sign in with my phone number and password — or continue straight into the
app as a guest — so that I can reach the main app without re-registering.

## Acceptance Criteria (EARS notation)

- WHEN the Login screen loads, THE SYSTEM SHALL show a phone field (country
  flag + dial code + national number) and a password field, both empty, with
  the default country selected and the submit button enabled.
- WHEN the user taps the country flag/dial code, THE SYSTEM SHALL present the
  shared country picker (search + list of 12 countries); selecting a country
  SHALL update the dial code shown in the phone field.
- WHEN the user types into the phone or password field, THE SYSTEM SHALL NOT
  re-render the field's text (to avoid moving the cursor), and SHALL clear any
  previously shown field error for that field.
- WHEN the user taps "Đăng nhập" (submit) with an empty or invalid phone
  number (below the selected country's minimum digit count) or an empty
  password, THE SYSTEM SHALL show an inline error on the offending field and
  SHALL NOT call the login use case. Password is validated as "non-empty only"
  — no minimum length is enforced at login.
- WHEN the user taps "Đăng nhập" with all fields valid, THE SYSTEM SHALL show
  a loading state on the submit button and call the login use case with the
  phone number in grouped, dial-code-prefixed display format (`+84 912 345
  678`), then either:
  - on success: navigate to the main app, or
  - on failure: show the returned error message and stay on the Login screen,
    with no navigation event emitted.

  The confirmed failure branches (from `Docs/Specs/API/openapi.yaml` v3.9,
  `POST /v1/auth/login`) that the future Data layer must map are:
  - wrong password / unknown number / number only in `pending_registration`
    → `401 INVALID_CREDENTIALS` (all three collapse to one code); five
    consecutive failures lock the number for 15 minutes (the fifth still
    answers 401, the next answers 429 even with the correct password);
  - `400` VALIDATION_ERROR / INVALID_PHONE / INVALID_PASSWORD / INVALID_DEVICE
    (none count as a failed attempt);
  - `429 LOGIN_LOCKED` — `details.locked_until` is when the lock lifts;
  - `413 PAYLOAD_TOO_LARGE`, `500 INTERNAL_ERROR`, and the transport cases
    (offline / timeout).

  These branches are **not implemented yet** — see Pending.
- WHEN a login request is already in flight, THE SYSTEM SHALL ignore a second
  tap on "Đăng nhập" and SHALL NOT submit the form twice.
- WHEN the user taps the back control, THE SYSTEM SHALL navigate to Onboarding.
- WHEN the user taps "Tạo tài khoản mới" (create account), THE SYSTEM SHALL
  navigate to the SignUp screen, keeping the Login screen on the navigation
  stack underneath.
- WHEN the user taps "Quên?" (forgot) next to the password field, THE SYSTEM
  SHALL navigate to the ForgotPassword screen.
- WHEN the user taps "Xem trước, đăng nhập sau" (guest preview), THE SYSTEM
  SHALL navigate to the main app without authenticating.

## Out of scope (this feature boundary, not backend work)

- Password recovery — owned by the ForgotPassword feature (see
  `Docs/Specs/ForgotPassword/`).
- Account creation — owned by the SignUp feature.
- The actual authentication request (`login`): the use case method is a
  one-line stub today (see Pending below). Building the real endpoint,
  repository implementation, and error mapping is Data-layer work that
  depends on a confirmed backend contract.

## Pending (not yet implemented — see `tasks.md`)

- The real `login` network call. `ILLoginUseCaseImpl.login` is currently
  `print("TODO: implement login — network/repository call, not built by
  ui-builder")`, which means the submit button **always succeeds** at
  runtime (it never throws `ILLoginError.invalidCredentials`). A Domain
  repository protocol `ILLoginRepository` exists, but there is no
  `Data/` implementation and the use case does not inject it yet.

  > The login API contract **is** confirmed — see `Docs/Specs/API/openapi.yaml`
  > v3.9, `POST /v1/auth/login` (`LoginRequest`: `phone_number`, `password`
  > non-empty, `device` {platform, device_model, os_version?, app_version?,
  > device_name?}; success `data` = `VerifyOTPData` {access_token,
  > refresh_token, user}). What is missing is the Data-layer implementation
  > and two entity/error gaps, not the contract:
  > - `ILLoginEntity` has only `phone`/`password`; the contract requires a
  >   `device` object (platform + device_model) that the entity does not carry.
  > - `ILLoginError` has only `.invalidCredentials`; the contract's mapped
  >   failures (VALIDATION_ERROR / INVALID_PHONE / INVALID_PASSWORD /
  >   INVALID_DEVICE / INVALID_CREDENTIALS / LOGIN_LOCKED / PAYLOAD_TOO_LARGE /
  >   INTERNAL_ERROR + transport) need matching cases.
  > (`tasks.md` Phase 3.)

- "Đăng nhập bằng mã SMS" (login via SMS OTP). The button renders but
  `handleSmsCodeTapped()` is an empty TODO; there is no OTP-for-login flow
  wired yet. The existing OTP feature (`Docs/Specs/Otp/`) only serves
  post-registration verification, not login. (`tasks.md` Phase 4.)

  > ⚠️ Not confirmed: whether the SMS-code login should reuse the OTP feature's
  > screen/flow (the contract's `ResendOTPRequest.purpose` enum already lists
  > `login`, but the note states "US-001 only implements register; the other
  > three return UNSUPPORTED_OTP_PURPOSE") — blocks `tasks.md` Phase 4.

## Open questions (resolved during implementation)

- ~~Is the email field part of login?~~ → No. Login is phone + password only
  (`login.title`/`login.subtitle` and the design handoff block `isLogin`).
  The design handoff has no email input. Resolved during implementation (see
  `Presentation/Scenes/Login/README.md`).
- ~~Is a password minimum length enforced at login?~~ → No, deliberately.
  `ILLoginUseCase.validatePassword` only rejects an empty password (matching
  `LoginRequest.password` in `Docs/Specs/API/openapi.yaml` v3.9: "Only checked
  for non-empty — the length floor is a registration rule"). The server is the
  authority on credentials. Resolved 2026-09-21 (recorded in
  `Docs/Specs/SignUp/` Password rule section).
