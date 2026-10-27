# Requirements — Onboarding

Version: 2.3
Last updated: 2026-10-27
Status: in-progress (drift) — splash, the three intro steps, the registration form, the code screen and the real register calls are built against the old phone + SMS contract; v2.0 moves registration to an email code (ADR-0003). The email registration call and the email code screen were built on 2026-10-27 (`tasks.md` Phases 3 and 5, partly), not yet built or tested on a Mac
Feature folder: `InnerLamp/Presentation/Scenes/{Splash,Onboarding,SignUp,Otp,AddTemple}/`
Product spec: innerlamp-be `docs/product/onboarding/product.md` @ v1.7
Contract: innerlamp-be `docs/specs/api/openapi.yaml` `info.version` 3.0.0 (Auth tag: `register/request-otp`, `register/resend-otp`, `register/verify-otp`, and the "Phiên bị thu hồi" note); backend feature spec `docs/specs/features/onboarding` @ v8.3.
Architecture: ADR-0003 (accounts identified by email, verified by an email code; SMS removed) — Accepted
Implements: BR-ONB-01, BR-ONB-02, BR-ONB-03, BR-ONB-04, BR-ONB-05, BR-ONB-06, BR-ONB-07, BR-ONB-08, BR-ONB-09, BR-ONB-10, BR-ONB-11, FR-ONB-001, FR-ONB-002, FR-ONB-003, FR-ONB-004, FR-ONB-005, FR-ONB-006, FR-ONB-007, FR-ONB-008, FR-ONB-009, FR-ONB-010, NFR-ONB-01, NFR-ONB-02, NFR-ONB-03
Not on iOS: FR-ONB-003 website row of product §3.6 (signed-in visitor opening the registration page)

> See `changelog.md` in this folder for the version history of this spec.

iOS platform spec (layer 2) of the first run and registration. Product behavior — when the intro
shows, launch routing, field rules, the 12-country list, the code policy, the account-exists notice,
the terms — lives in the product spec and is **not** restated here; this file only says how the iOS
app implements those `BR-ONB-*` / `FR-ONB-*`.

v2.0 merges the former `Docs/Specs/{Splash,Onboarding,SignUp,Otp}/` into this one folder, named after
the product slug. The scene folders in code keep their names. The old spec folders are deleted in the
docs clean-up step, after the four platform specs are approved.

## User Story

As someone opening InnerLamp on an iPhone for the first time, I want a short introduction and then to
create an account with my email, password, phone and name and confirm it with a code sent to my
email, so that I am signed in and my practice journey is kept on every device.

## Acceptance Criteria (EARS notation)

### Splash, intro and launch routing

1. WHEN the app launches, THE SYSTEM SHALL show the splash (wordmark, tagline) and advance on its own; then open Main if a session is stored, otherwise the intro if `has_completed_onboarding` is not set, otherwise **Login** as the root (not SignUp). (FR-ONB-002, BR-ONB-02)
2. WHEN the app launches for the first time after install (the `UserDefaults` flag is missing), THE SYSTEM SHALL delete any session left in the Keychain by a previous install before routing. (BR-ONB-01, platform — the Keychain survives reinstall)
3. WHEN the intro shows, THE SYSTEM SHALL show the three steps of product §3.1.1 with "Bỏ qua" and a progress bar; step 1 offers "Bắt đầu" and "Tôi đã có tài khoản", steps 2–3 offer "Quay lại". (FR-ONB-001)
4. WHEN the user chooses "Tạo tài khoản" on step 3, "Bỏ qua" on any step, or "Tôi đã có tài khoản" on step 1, THE SYSTEM SHALL set `has_completed_onboarding` before leaving the intro; "Tôi đã có tài khoản" opens Login, the other two open SignUp. (FR-ONB-001, BR-ONB-01)
5. WHEN the user picks wishes (step 2) or bell times (step 3), THE SYSTEM SHALL keep them in `UserDefaults` only and SHALL NOT send them to the backend. (BR-ONB-03)
6. WHEN the user signs out, THE SYSTEM SHALL keep `has_completed_onboarding` and the intro choices. (BR-ONB-01, `login` BR-LGN-07)

### Registration form (SignUp)

7. WHEN SignUp opens, THE SYSTEM SHALL show, in the order of product §3.1.1: full name (empty), dharma name (**empty**, with "Gợi ý"), ordination temple, phone (country + number), email with the hint that it is used to sign in and to receive the code, password (reveal toggle + strength hint) and the terms row; the button is "Đăng ký", with a link to Login. (FR-ONB-003, BR-ONB-07)
8. WHEN the user chooses "Gợi ý", THE SYSTEM SHALL fill the dharma name with the next of the 10 suggestions; the user may keep, edit or clear it. (BR-ONB-07)
9. WHEN the user submits, THE SYSTEM SHALL check every field with the rules of BR-ONB-04…07 — phone digits exactly the country's length after dropping spaces, dots, dashes and one leading 0; email trimmed and matched; password 8–64 **characters** after NFC; full name 1–300 and dharma name 0–255 characters after trimming — and on any error show it under the field, keep every value and SHALL NOT call the backend. (FR-ONB-003, BR-ONB-04, BR-ONB-05, BR-ONB-06, BR-ONB-07)
10. WHEN the user types a password, THE SYSTEM SHALL show the 3-level strength hint as advice only; it SHALL NOT block submitting. (BR-ONB-06, §3.6)
11. WHILE the terms are not accepted, THE SYSTEM SHALL keep "Đăng ký" disabled. (BR-ONB-11)
12. WHEN the user opens the terms of use or the privacy policy from the terms row, THE SYSTEM SHALL keep today's in-app sheet with the bundled text and, on dismiss, return to SignUp with every value and the checkbox unchanged. Moving to the one shared text (BR-ONB-11) is deferred. (BR-ONB-11, platform)
13. WHEN the user submits a valid form, THE SYSTEM SHALL call `POST /v1/auth/register/request-otp` with `email` (trimmed), `password`, `phone_country` (ISO code of the picked country) and `phone_number` (digits as typed, not rebuilt into E.164), `full_name`, `dharma_name` only when not empty and `ordination_temple_id` only when a listed temple is picked, then:
    - on success: open the code screen with the email and the server's `expires_in_seconds` / `resend_after_seconds`;
    - on failure: stay on SignUp, keep every value, show the error per the Error → UI table. (FR-ONB-003, BR-ONB-08, BR-ONB-09)
14. WHEN the email already has an account, THE SYSTEM SHALL behave exactly as for a new email (the backend answers `200` with the same body and mails that address a notice instead of a code); there is no "email taken" message any more, and the code screen then answers `OTP_INVALID` whatever is typed. (BR-ONB-08, NFR-ONB-01)
15. WHEN the backend answers `PHONE_TAKEN`, THE SYSTEM SHALL show "Số điện thoại này đã được đăng ký" under the phone field with a link to Login, and stay. (FR-ONB-005)
16. WHEN a submit is already in flight, THE SYSTEM SHALL ignore another tap. (platform)
16a. WHEN the backend answers `REGISTRATION_IN_PROGRESS` (another pending registration holds this email with a live code and different details), THE SYSTEM SHALL stay on SignUp, keep every value and show "Vui lòng chờ N giây rồi thử lại" with N = `details.retry_after_seconds` (never a client-chosen number); no email is sent, the pending registration is unchanged and the earlier code still works. Resubmitting the same details instead replaces the code and opens the code screen (criterion 13). (BR-ONB-08, FR-ONB-003; confirmed by anh Đức 2026-10-16, `Docs/Assumptions/Onboarding/AS-Onboarding-001-registration-in-progress-copy.md`)

### Ordination temple and temple proposal

17. WHEN the user opens the ordination temple field, THE SYSTEM SHALL list `GET /v1/temples/options` page by page with "Chưa xuất gia — Cư sĩ tu tại gia" first and server search by name (debounced; a stale answer is dropped). (FR-ONB-004, BR-ONB-10)
18. WHEN the user proposes a missing temple, THE SYSTEM SHALL require its name and a province and ward picked from the administrative-unit list, the street line optional; the proposal is kept with the registration, never sent as `ordination_temple_id`. (FR-ONB-006, BR-ONB-10)
19. WHEN the account has just been created and a proposal is kept, THE SYSTEM SHALL send it once with `POST /v1/temple-suggestions` (public, no token); a failure SHALL NOT affect the registration and is not shown as an error. (FR-ONB-006)

### Email code (Otp)

20. WHEN the code screen opens, THE SYSTEM SHALL show "Đã gửi tới <email>", a 6-digit entry, a live countdown of the time the code stays valid (from `expires_in_seconds`) and "Gửi lại mã" disabled with the seconds left (from `resend_after_seconds`); there is no voice-call banner. (FR-ONB-007, FR-ONB-008, BR-ONB-09)
21. WHEN the user enters 6 digits and confirms, THE SYSTEM SHALL call `POST /v1/auth/register/verify-otp` with the email and the code, and on success store the session as sign-in does (`Docs/Specs/Login/`), send the temple proposal (criterion 19) and open Main. (FR-ONB-007)
22. WHEN the countdown reaches zero, THE SYSTEM SHALL say the code has expired and point to "Gửi lại mã"; the clients never assume their own durations. (FR-ONB-008, BR-ONB-09)
23. WHEN the user chooses "Gửi lại mã" after the wait, THE SYSTEM SHALL call `POST /v1/auth/register/resend-otp` with the email, clear the entry and restart both timers from the response. (FR-ONB-008)
24. WHEN the backend answers `OTP_LOCKED` or `OTP_SEND_LIMITED`, THE SYSTEM SHALL show the unlock time from `locked_until` in device local time; `OTP_LOCKED` disables the entry until then, `OTP_SEND_LIMITED` keeps the entry usable for the last code. (FR-ONB-007, FR-ONB-008, BR-ONB-09)
25. WHEN the user chooses "Đổi email", THE SYSTEM SHALL return to SignUp with every value as left, password included. (FR-ONB-009)
26. WHEN the backend answers `PENDING_REGISTRATION_EXPIRED`, THE SYSTEM SHALL show "Thời gian đăng ký đã hết. Vui lòng đăng ký lại từ đầu." and return to SignUp with every value as left. (FR-ONB-010)
26a. WHEN `verify-otp` answers `PHONE_TAKEN` (the number was taken while the code was pending) or `INVALID_TEMPLE` (the picked temple was removed meanwhile), THE SYSTEM SHALL NOT create an account, return from the code screen to SignUp (step 1) with every value kept, and show the error at the related field: "Số điện thoại này đã được đăng ký" beside the phone field, or a request to pick the temple again beside the temple field. (BR-ONB-08, FR-ONB-004, FR-ONB-005; product spec v1.7)

### General

27. WHEN an error is shown, THE SYSTEM SHALL use only localized strings, never the backend's `error.message`; `RATE_LIMITED` shows "try again later" with the wait from `retry_after_seconds`. (NFR-ONB-02)
28. WHEN the app logs requests or errors, THE SYSTEM SHALL never log the password, the code or tokens. (NFR-ONB-03)
29. WHEN the app calls any `/v1/auth/*` route, THE SYSTEM SHALL NOT send `X-API-Key` or `X-InnerLamp-Client-IP` (website-only headers; see `../Login/requirements.md` criterion 24). (platform)
30. WHEN unit tests run, THE SYSTEM SHALL pass every case of `rules/phone-number.json`, `rules/email.json`, `rules/password.json` and `rules/names.json` with the app's validators. (BR-ONB-04…07)

## Data & API

| Action | Operation | Note |
|---|---|---|
| Submit the form | `POST /v1/auth/register/request-otp` | Email + `phone_country` instead of a phone-keyed body |
| Resend the code | `POST /v1/auth/register/resend-otp` | New path (was `/v1/auth/resend-otp` with `purpose`); body `{email}` only; answer adds `resend_remaining`, which iOS does not use |
| Verify the code | `POST /v1/auth/register/verify-otp` | Email + code; returns a session like sign-in |
| Temple list | `GET /v1/temples/options` | Unchanged |
| Provinces / wards | administrative-unit routes used by AddTemple | Unchanged |
| Temple proposal | `POST /v1/temple-suggestions` | Now sent (was local only, TD-SignUp-002) |

Request and response shapes: the contract in the header. This file copies no schema.

## Error → UI mapping

| Case | What the user sees |
|---|---|
| `INVALID_EMAIL` / `INVALID_PHONE` / `INVALID_PASSWORD` / `INVALID_FULL_NAME` / `INVALID_DHARMA_NAME` | Error under that field |
| `INVALID_TEMPLE` | Error on the temple field, asks to pick again (also from `verify-otp`: criterion 26a) |
| `VALIDATION_ERROR` | Generic invalid-input message |
| `PHONE_TAKEN` | Criterion 15; from `verify-otp`, criterion 26a |
| `REGISTRATION_IN_PROGRESS` | Criterion 16a |
| `OTP_RESEND_TOO_SOON` | Resend timer restarted from `details.retry_after_seconds` |
| `OTP_SEND_LIMITED` | Unlock time; last code still usable (criterion 24) |
| `OTP_INVALID` | "Mã xác thực không đúng" (also what an email that already has an account always gets) |
| `OTP_EXPIRED` | Expired message, "Gửi lại mã" emphasised |
| `OTP_LOCKED` | Unlock time, entry disabled until then (criterion 24) |
| `PENDING_REGISTRATION_EXPIRED` | Criterion 26 |
| `RATE_LIMITED` | Try again later, with the wait from `details.retry_after_seconds` (same as the `Retry-After` header); per-IP limit of the `/v1/auth/*` routes |
| `EMAIL_SEND_FAILED`, 5xx | Generic error |
| Offline / timeout | Shared no-internet / retry message |

## Out of scope

- Sign-in, session, sign-out, forgot password, guest mode → `Docs/Specs/Login/`.
- Changing email or phone, deleting the account, Google / Apple sign-in → later (product §1.2).
- Scheduling the intro bells as notifications → not part of this product spec.

## Pending (not yet implemented)

Everything moving from phone + SMS to email, the launch routing change and
sending the temple proposal — `tasks.md` Phase 1–7.

> Deferred (anh Đức, 2026-10-14): the terms part of BR-ONB-11 (one shared text) is left for later;
> SignUp keeps its bundled legal sheet until then.

## Open questions (resolved)

- ~~Folder layout?~~ → One `Onboarding/` spec per product slug, like the backend and website; the old `Splash/`, `SignUp/`, `Otp/` spec folders are deleted in the clean-up step. Claude's default, reviewed with this PR. Resolved 2026-10-14.
- ~~Where does the terms text come from?~~ → Left for later; the bundled sheet stays for now (anh Đức: "bỏ qua phần điều khoản, chúng ta sẽ làm sau"). Resolved 2026-10-14.
- ~~Does the backend accept the temple proposal?~~ → Yes: `POST /v1/temple-suggestions` is live and public (no access token; rate limited per device address), backend temple-suggestion v3.4 US-TSG-01. iOS sends it (criterion 19). Resolved 2026-10-14.
- ~~Launch routing?~~ → First launch: intro, flag set, then SignUp. Any later launch (app killed and reopened) without a session: Login (anh Đức, 2026-10-14; criteria 1, 4). Resolved 2026-10-14.
- ~~Does "Tôi đã có tài khoản" mark the intro as seen?~~ → Yes (product FR-ONB-001 scenario). Resolved 2026-10-14.
- ~~Keep the password on "Đổi email" / registration expired?~~ → Keep every field (FR-ONB-009, FR-ONB-010). Resolved 2026-10-14.
- ~~Live countdown or a fixed "valid for" text?~~ → Live countdown of the time left (FR-ONB-008). Resolved 2026-10-14.
