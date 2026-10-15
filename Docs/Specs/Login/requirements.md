# Requirements — Login

Version: 2.1
Last updated: 2026-10-15
Status: in-progress (drift) — sign-in by phone, Keychain session, single-flight refresh and sign-out are built and call the real backend; v2.0 moves sign-in to email, adds forgot password by email code, explains an ended session and gates account features for guests. No code for v2.0 yet (`tasks.md` Phase 1–7)
Feature folder: `InnerLamp/Presentation/Scenes/{Login,ForgotPassword}/`, `Core/Networking/AuthSessionRefresher.swift`, `App/AppCoordinator.swift`, `Domain/UseCases/Profile/ILProfileUseCase.swift` (sign-out)
Product spec: innerlamp-be `docs/product/login/product.md` @ v1.2
Contract: innerlamp-be `docs/specs/features/login/requirements.md` @ v2.2 §API contract (47122d1); refresh and logout unchanged from `openapi.yaml`. `openapi.yaml` has neither email sign-in nor `password-reset/*` yet — the backend updates it when the handlers ship.
Architecture: ADR-0003 — Accepted
Implements: BR-LGN-01, BR-LGN-02, BR-LGN-03, BR-LGN-04, BR-LGN-05, BR-LGN-06, BR-LGN-07, FR-LGN-001, FR-LGN-002, FR-LGN-003, FR-LGN-004, FR-LGN-005, FR-LGN-006, FR-LGN-008, FR-LGN-009, FR-LGN-010, NFR-LGN-01, NFR-LGN-02, NFR-LGN-03
Not on iOS: FR-LGN-007 (website only)

> See `changelog.md` in this folder for the version history of this spec.

iOS platform spec (layer 2) of sign-in, session, sign-out, forgot password and guest mode. The rules —
uniform wrong-credentials message, the 5-attempt lock, 7-day sliding session, reset policy, what a
guest may open — live in the product spec and are **not** restated here.

v2.0 merges the former `Docs/Specs/ForgotPassword/` into this folder (deleted in the clean-up step).

## User Story

As a member, I want to sign in with my email and password, stay signed in, be told when my session has
ended, and reset a forgotten password with a code sent to my email — or browse as a guest — so that I
can reach InnerLamp on my iPhone without help.

## Acceptance Criteria (EARS notation)

### Sign-in

1. WHEN Login opens, THE SYSTEM SHALL show the email field, the password field with "Hiện/Ẩn", "Đăng nhập", "Quên mật khẩu?", "Tạo tài khoản mới" and "Vào xem trước, chưa đăng nhập"; there is no phone field, no country picker and no "Gửi mã một lần qua SMS". (FR-LGN-001, FR-LGN-010)
2. WHEN the user submits with an empty email or an empty password, THE SYSTEM SHALL show the error under that field and SHALL NOT call the backend; no length rule applies to the password here. (BR-LGN-01)
3. WHEN the user submits, THE SYSTEM SHALL call `POST /v1/auth/login` with the trimmed email, the password and `device {platform: "ios", device_model, os_version, app_version}`, then:
   - on success: store the session (criterion 8) and open Main;
   - on failure: stay, keep the email, clear the password, show the error per the Error → UI table. (FR-LGN-001, FR-LGN-002)
4. WHEN the backend answers `INVALID_CREDENTIALS`, THE SYSTEM SHALL show "Email hoặc mật khẩu không đúng". (FR-LGN-002, BR-LGN-01, NFR-LGN-01)
5. WHEN the backend answers `LOGIN_LOCKED`, THE SYSTEM SHALL show the lock message with the unlock time from `locked_until` in device local time. (FR-LGN-003, BR-LGN-02)
6. WHEN a sign-in is in flight, THE SYSTEM SHALL ignore another tap. (platform)
7. WHEN Login is the root (launch without a session, after sign-out, session ended), THE SYSTEM SHALL show no back control; when pushed from SignUp, back returns to SignUp. (FR-ONB-002, platform)

### Session

8. WHEN sign-in or registration succeeds, THE SYSTEM SHALL keep the access and refresh tokens only in the Keychain with a `ThisDeviceOnly` accessibility (today `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`), never synced or backed up, and the user in Core Data. (NFR-LGN-03, BR-LGN-03)
9. WHEN the app launches with a stored session, THE SYSTEM SHALL open Main without asking for the password. (FR-LGN-004)
10. WHEN an authenticated call answers `401`, THE SYSTEM SHALL refresh once (single-flight across concurrent calls, the rotated pair saved before the retry) and retry the call; an offline / timeout / 5xx refresh leaves the session for a later try. (FR-LGN-004, BR-LGN-03)
11. WHEN the refresh is refused (`REFRESH_TOKEN_INVALID`) or no refresh token is stored while a session existed, THE SYSTEM SHALL clear the tokens and every user-scoped local data (the same cleanup as sign-out), open Login as the root and show "Phiên đăng nhập đã hết, vui lòng đăng nhập lại."; it SHALL NOT drop the user silently. (FR-LGN-005, BR-LGN-04)
12. WHEN a guest (no session ever stored) hits a `401`, THE SYSTEM SHALL NOT treat it as an ended session (no clean-up, no message); the guest prompt of criterion 21 applies instead. (BR-LGN-06, platform)

### Sign-out

13. WHEN the user chooses "Đăng xuất" on the Me tab, THE SYSTEM SHALL ask for confirmation; cancel keeps the session; confirm calls `POST /v1/auth/logout` (result ignored), deletes the tokens and user-scoped local data, keeps device settings (`has_completed_onboarding`, intro choices) and opens Login as the root, also when offline. (FR-LGN-006, BR-LGN-07)

### Forgot password

14. WHEN the user chooses "Quên mật khẩu?", THE SYSTEM SHALL open the request view with the email field (pre-filled from Login when typed), "Gửi mã" and "Trở lại đăng nhập"; the phone field, the "đổi số điện thoại" notice and "Gửi hướng dẫn" are removed. (FR-LGN-008)
15. WHEN the user submits a valid email, THE SYSTEM SHALL call `POST /v1/auth/password-reset/request-otp` and, whatever the email, open the new-password view with "Nếu email này có tài khoản, mã đã được gửi", the email, a live countdown of the code's validity and the resend wait, both from the response. (FR-LGN-008, BR-LGN-05, NFR-LGN-01)
16. WHEN the user chooses "Gửi lại mã" after the wait, THE SYSTEM SHALL call the same request again, clear the code and restart both timers. (FR-LGN-008)
17. WHEN the user enters 6 digits and a new password, THE SYSTEM SHALL check the password with the BR-ONB-06 rule (the onboarding validator) and then call `POST /v1/auth/password-reset/confirm`; on success, if this device holds a session it is cleared as in criterion 13 (without the logout call), and Login opens as the root with "Đã đổi mật khẩu, vui lòng đăng nhập lại." and the email pre-filled. (FR-LGN-009, BR-LGN-05)
18. WHEN confirm fails, THE SYSTEM SHALL stay on the new-password view, keep the code, clear the new password and show the error; `OTP_LOCKED` disables the entry until `locked_until`. (FR-LGN-009)
19. WHEN the password was reset on another device, THE SYSTEM SHALL handle this device's next `401` per criteria 10–11. (FR-LGN-005, FR-LGN-009)

### Guest

20. WHEN the user chooses "Vào xem trước, chưa đăng nhập", THE SYSTEM SHALL open Main as a guest; public content opens normally. (FR-LGN-010, BR-LGN-06)
21. WHEN a guest opens something that belongs to an account (memorial book, family tree, practice records, profile, notifications), THE SYSTEM SHALL show the shared sign-in prompt (explanation, "Đăng nhập", "Tạo tài khoản") instead of the screen and SHALL NOT call the backend for it. (FR-LGN-010, BR-LGN-06)

### General

22. WHEN an error is shown, THE SYSTEM SHALL use only localized strings, never the backend's `error.message`; `RATE_LIMITED` shows "try again later" with the wait from `retry_after_seconds`. (NFR-LGN-02)
23. WHEN the app logs requests or errors, THE SYSTEM SHALL never log passwords, codes or tokens. (NFR-LGN-03)

## Data & API

| Action | Operation | Note |
|---|---|---|
| Sign in | `POST /v1/auth/login` | `email` instead of `phone_number` |
| Refresh | `POST /v1/auth/refresh` | Unchanged |
| Sign out | `POST /v1/auth/logout` | Unchanged |
| Ask for a reset code | `POST /v1/auth/password-reset/request-otp` | New |
| Set a new password | `POST /v1/auth/password-reset/confirm` | New |

Request and response shapes: the contract in the header. This file copies no schema.

## Error → UI mapping

| Case | What the user sees |
|---|---|
| `INVALID_CREDENTIALS` | "Email hoặc mật khẩu không đúng" |
| `LOGIN_LOCKED` | Lock message with the unlock time |
| `INVALID_EMAIL` | Error under the email field |
| `INVALID_PASSWORD` (reset) | Error under the new password |
| `OTP_INVALID` / `OTP_EXPIRED` / `OTP_LOCKED` / `OTP_RESEND_TOO_SOON` / `OTP_SEND_LIMITED` | As the registration code screen (`../Onboarding/requirements.md` Error → UI) |
| `RATE_LIMITED` | Try again later, with the wait |
| `REFRESH_TOKEN_INVALID`, `401` after refresh | Session ended (criterion 11) |
| `INVALID_DEVICE`, 5xx | Generic error |
| Offline / timeout | Shared no-internet / retry message |

## Out of scope

- Registration and the email code → `../Onboarding/`.
- Sign-in by code, Google / Apple, sign out of every device, change password while signed in → later (product §1.2).
- Each feature's own guest handling beyond showing the shared prompt (e.g. `Docs/Specs/Memorial/`).

## Pending (not yet implemented)

`tasks.md` Phase 1–7.

## Open questions (resolved)

- ~~Folder layout?~~ → One `Login/` spec per product slug; `ForgotPassword/` merged here and deleted in the clean-up step. Claude's default, reviewed with this PR. Resolved 2026-10-14.
- ~~Keep the password after a failed sign-in?~~ → Clear it, keep the email (product §3.7 keeps the email only). Resolved 2026-10-14.
- ~~"Gửi mã một lần qua SMS"?~~ → Removed (no sign-in by code). Resolved 2026-10-14.
- ~~Is a guest's `401` a session end?~~ → No; a guest never had a session, so the guest prompt applies (criteria 12, 21). Resolved 2026-10-14.
- ~~After a successful reset, signed in automatically?~~ → No (BR-LGN-05); Login opens with the email pre-filled. Resolved 2026-10-14.
