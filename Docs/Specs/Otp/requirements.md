# Requirements — Otp

Version: 1.1
Last updated: 2026-09-23
Status: in-progress — UI + local logic + API integration done; only the
manual real-backend test pending (see `tasks.md` Phase 3)
Feature folder: `InnerLamp/Presentation/Scenes/Otp/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec was written after the SignUp spec. The full registration flow is two
> calls — `request-otp` (SignUp) then `verify-otp` (this feature) — and the new
> screens/calls that used to be listed as "Deferred" in `Docs/Specs/SignUp/tasks.md`
> are owned here.

## User Story

As a new visitor who has just submitted the SignUp form, I want to enter the
6-digit code sent to my phone, so that my account is created, I am signed in,
and I can continue into the app.

## Acceptance Criteria (EARS notation)

- WHEN the OTP screen loads, THE SYSTEM SHALL show the phone number the code was
  sent to, a 6-digit code input, a "Gửi lại" row, the voice-call banner, and a
  "Xác nhận" button disabled until exactly 6 digits are entered.
- WHEN the screen loads, THE SYSTEM SHALL seed the "Gửi lại" countdown and the
  code-expiry message from the server's `resend_after_seconds` /
  `expires_in_seconds` returned by the preceding `request-otp` call, instead of
  the previously hardcoded values (47s / "10 phút").
- WHEN the user taps "Xác nhận" with a complete 6-digit code, THE SYSTEM SHALL
  call `POST /v1/auth/register/verify-otp` and, on success (HTTP 201):
  - store the returned `access_token` in the Keychain under the app's access-token
    key, so later authenticated requests carry it;
  - store the returned `refresh_token` in the Keychain for the (not yet
    implemented) refresh flow;
  - store the returned `user` locally;
  - navigate to the main app.
- WHEN verify fails, THE SYSTEM SHALL stay on the screen, keep the entered code,
  and show the corresponding error:
  - `400 OTP_INVALID` (wrong code) → "Mã xác thực không đúng. Vui lòng thử lại."
  - `400 OTP_EXPIRED` (the 90s code window closed) → an expired-code message;
  - `400 PENDING_REGISTRATION_EXPIRED` (the 24h payload expired) → a
    restart-registration message;
  - `409 PHONE_TAKEN` / `EMAIL_TAKEN` → the phone/email-already-registered
    message;
  - `429 OTP_LOCKED` → the locked message (including when sending unlocks, when
    the server provides `details.locked_until`);
  - `500 INTERNAL_ERROR` → the shared generic error;
  - offline or timeout → the shared no-internet / retry error.
- WHEN the user taps "Gửi lại" and the cooldown has elapsed, THE SYSTEM SHALL
  call `POST /v1/auth/resend-otp` with `purpose = "register"` and restart the
  countdown and expiry message from the returned `resend_after_seconds` /
  `expires_in_seconds`.
- WHEN a resend fails, THE SYSTEM SHALL stay on the screen, keep the code, and
  show the corresponding error: `400 OTP_INVALID` (no live pending registration)
  → restart-registration message; `400 PENDING_REGISTRATION_EXPIRED` →
  restart-registration message; `429 OTP_RESEND_TOO_SOON` → "try again in N
  seconds" when `details.retry_after_seconds` is present; `429 OTP_LOCKED` /
  `OTP_SEND_LIMITED` → locked/limited message; `500 SMS_SEND_FAILED` /
  `INTERNAL_ERROR` → the shared generic error.
- WHEN the user taps the voice-call banner, THE SYSTEM SHALL NOT call the
  backend, because the confirmed `resend-otp` contract has no channel field; the
  voice channel is deferred.

  > ⚠️ Not confirmed: whether/how the backend supports a voice-call OTP channel.
  > `ResendOTPRequest` in `Docs/Specs/API/openapi.yaml` v3.9 carries only
  > `phone_number` + `purpose`; no voice variant exists. Blocks implementing the
  > banner beyond a "not available yet" message.
- WHEN the user taps back or "Đổi số", THE SYSTEM SHALL return to the previous
  screen (SignUp / ForgotPassword) without changing any of its state.

## Out of scope (feature boundary)

- Login (`POST /v1/auth/login`) and token refresh (`POST /v1/auth/refresh`) —
  separate features. This feature only *stores* the refresh token.
- ForgotPassword's own OTP-request path; its OTP entry reuses this screen, but
  its timing source is its own (not yet implemented) request.
- The voice-call OTP channel (see the ⚠️ above).

## Pending (not yet implemented — see `tasks.md` Phase 3)

- Real `POST /v1/auth/register/verify-otp` + `POST /v1/auth/resend-otp`
  integration against the confirmed contract in
  `Docs/Specs/API/openapi.yaml` (v3.9). Currently `verifyCode`/`resendCode` are
  one-line `print("TODO: …")` stubs with no network call.
- `ILUserEntity` / the Core Data store do not model the server's
  `user.created_at`; it is not persisted today. Needed only if something starts
  displaying it.

## Open questions (resolved during implementation)

- ~~Where should the tokens/user from a successful `verify-otp` be stored?~~ →
  In the Keychain (access token under the app's existing access-token key,
  refresh token under a new key) and the user through `ILUserRepository`, done
  inside `ILOtpUseCaseImpl`, keeping `verifyCode(...) -> Void`. Resolved
  2026-09-23 (user).
- ~~Should the OTP screen use the server's `expires_in_seconds` /
  `resend_after_seconds`, or keep the hardcoded 47s / "10 phút"?~~ → Use the
  server values. This also resolved SignUp's long-open ⚠️: `request-otp`'s
  timing is passed through the `.didRequestVerification` navigation event to
  this screen. Resolved 2026-09-23 (user).
- ~~How should the voice-call banner behave, given the API has no channel?~~ →
  Deferred: the banner must not call the backend until a voice channel is
  confirmed. Resolved 2026-09-23 (user).
