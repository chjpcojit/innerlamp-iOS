# Changelog — Otp Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this folder. All
three files share one changelog since they change together as one spec unit. Newest version first.

## v1.1 (2026-09-23)

- `requirements.md`: header only — Status moved from "integration pending" to "API integration
  done, manual real-backend test pending"; no line of prose changed.
- `design.md`: header only — same Status change; no line of prose changed. The design as written
  is what shipped.
- `tasks.md`: Phase 3 ticked for the work that landed — `ILOtpTimingEntity`, the verify/resend
  DTOs, `ILOtpMapper`, `VerifyRegistrationOTPEndpoint` / `ResendOTPEndpoint`, `ILOtpRepository` +
  `ILOtpRepositoryImpl`, the `ILOtpError` extension + operation-aware `from(_:operation:)`, the
  repository/Keychain/`ILUserRepository` injection and stub replacement, `DIContainer` wiring,
  the server-driven countdown/expiry across the OTP screen **and** SignUp's timing pass-through,
  and the test rework. Phase 4's README update ticked; the OKF concept and the manual
  real-backend test stay `[ ]`.
- Code (Otp): `verifyCode` calls `POST /v1/auth/register/verify-otp` and persists the returned
  session — `access_token` under `KeychainAuthTokenProviding.accessTokenKey`, `refresh_token`
  under `ILOtpUseCaseImpl.refreshTokenKey`, `user` via `ILUserRepository`; `resendCode` calls
  `POST /v1/auth/resend-otp` (`purpose = "register"`) and returns the server timing, except
  `.voiceCall` which throws `.voiceCallUnsupported` with no network call. New `otp.error.*` /
  `otp.expiry.*` keys in `vi.json`; the previously hardcoded 47s / "10 phút" are gone.
  `ILUnlockTimeFormatter` was extracted so SignUp and Otp share the `locked_until` formatting.
- Tests: `ILOtpViewModelTests` updated (11), plus new `ILOtpRepositoryTests` (26),
  `ILOtpUseCaseTests` (5, real Keychain + in-memory Core Data), and the SignUp suites updated.
  All pass. Two unrelated pre-existing failures remain: `ILSplashViewModelTests`
  (`handleSplashFinished` returns `.goToMain`, marked "TEMP DEBUG — revert") and a flaky
  `ILForgotPasswordViewModelTests` case with a fixed 0.3s wait (passes on re-run).
- Reason: the user asked to continue past `request-otp` into OTP verification and confirmed the
  three design decisions recorded in v1.0.

## v1.0 (2026-09-23)

- Initial spec for the OTP feature (`InnerLamp/Presentation/Scenes/Otp/`), written now that its
  half of the registration flow has a confirmed contract — `POST /v1/auth/register/verify-otp`
  and `POST /v1/auth/resend-otp` in `Docs/Specs/API/openapi.yaml` v3.9. Previously these two
  calls were listed only as "Deferred" in `Docs/Specs/SignUp/tasks.md`.
- `requirements.md`: user story + EARS criteria for verify (session stored, every named failure
  surfaced, stay on screen), resend (timing reseeded from the server), the voice-call banner
  (deferred, ⚠️ no channel in the contract), and back/"Đổi số". Three implementation questions
  are recorded as resolved (2026-09-23, user): session persistence location, server-driven
  timing, and the deferred voice channel. Records that `user.created_at` is not persisted.
- `design.md`: layers table (new Entity/Repository/DTO/Mapper/Endpoints + the modified SignUp
  pieces), navigation flow, verify/resend data flows, the confirmed Step-by-step Flow, the
  session-persistence table (access token under `KeychainAuthTokenProviding.accessTokenKey`,
  refresh token under a new key, user via `ILUserRepository`), and known edge cases —
  including that `OTP_INVALID` means a wrong code on verify but "no pending registration" on
  resend, so the error mapping is operation-aware.
- `tasks.md`: Phase 1 (UI) and Phase 2 (Domain/local logic, still stubbed) marked done; Phase 3
  written prospectively with every box `[ ]`; Deferred lists the voice channel, login/refresh,
  and `created_at`.
- Reason: the user asked to continue the registration work past `request-otp` into the OTP
  verify/resend calls, and confirmed the three design decisions above.
