# Changelog — Login Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v2.2 (2026-10-16)

Aligned with innerlamp-be `docs/specs/api/openapi.yaml` `info.version` 2.1.1, product spec `login` @ v1.4
(matrix column only, no requirement changed) and backend login spec v2.5. Docs only; no code changed.

- `requirements.md`: header cites openapi 2.1.1 as the contract (the "openapi has no email shapes yet"
  note is gone); criterion 3 says only `device_model` is required (`platform` optional, iOS still sends it); criterion 10 adds that the backend
  checks the session on every call (so `401 UNAUTHORIZED` can come at once after sign-out, a reset or a
  same-device sign-in) and that `503 SERVICE_UNAVAILABLE` is transient, not a session end; criterion 17
  adds that confirm returns no token and lifts `LOGIN_LOCKED`; new criterion 24 (no `X-API-Key` /
  `X-InnerLamp-Client-IP` from mobile); Data & API and Error → UI rows updated (`RATE_LIMITED` wait,
  `INVALID_DEVICE`, confirm `OTP_EXPIRED` for an unknown email).
- `design.md`: session-renewal flow covers `503` and the refresh answer shape; the "stubbed" note now
  says the backend work is uncommitted and not yet run against a server.
- `tasks.md`: new items for the `503` handling and the no-web-headers rule.

## v2.1 (2026-10-15)

- Docs clean-up done after the four platform specs were approved (Android merged 2026-10-15). Deleted:
  `Docs/Specs/{SignUp,Otp,Splash,ForgotPassword}/`, `Login/SRS.md`, `Onboarding/SRS.md`,
  `Docs/Knowledge/features/{signup,otp,login,forgot-password,onboarding,splash}.md`, `Docs/Knowledge/api/`
  (three `auth-*` concepts), `Docs/Assumptions/{SignUp,Splash}/`, `TD-SignUp-001`, `TD-SignUp-005`.
  Kept: `TD-SignUp-002/003/004`, `TD-Splash-001/002` (still true of the code; closed when it changes).
  Links to the deleted files (Knowledge, scene READMEs, code comments, the `spec-writer` / `okf-writer` /
  `data-builder` skills) now point to this folder or say the file is in git history.
- `tasks.md`: the clean-up item ticked. `requirements.md` / `design.md` unchanged apart from the version.

## v2.0 (2026-10-14)

Rewritten against the product spec innerlamp-be `docs/product/login/product.md` @ v1.2 (ADR-0003
Accepted) and the backend login spec v2.2. Docs only; no code changed.

- Scope: sign-in, session, sign-out, forgot password and guest mode. Merges `Docs/Specs/ForgotPassword/`
  (deleted in the clean-up step).
- `requirements.md`: header `Product spec` / `Contract` / `Architecture` / `Implements`; criteria 1–23
  tagged with product IDs. Email replaces phone; SMS button removed; password cleared after a failed
  sign-in; Login as root has no back; session end clears every user-scoped data and shows "Phiên đăng
  nhập đã hết"; a guest's 401 is not a session end; forgot password by email code with new password,
  ends a stored session and returns to Login with the email pre-filled; shared guest prompt.
- `design.md`: shared `ILAuthSessionStore`; layers table with a State column; Step-by-step Flows for
  session renewal / end and forgot password.
- `tasks.md`: Phases 1–7; `[x]` only where the code was read and still matches (Keychain, refresh,
  device object, lock time, sign-out, guest entry).
- Review (anh Đức, 2026-10-14): the session-ended message needs new UI → design note + task.
- Hand-offs: product — none. Backend — none.
- Reason: anh Đức dropped SMS (2026-10-14).

## v1.2 (2026-09-28)

- `tasks.md`: Phase 3 (API integration) implemented by `il-data-layer-builder`
  — `requirements.md`/`design.md` prose unchanged (per that skill's remit),
  only `tasks.md` checkboxes ticked. Added: `ILLoginDTO`/`ILLoginMapper`
  (`Data/DTOs/`, `Data/DTOs/Mappers/`), `LoginEndpoint`
  (`Data/DataSources/Remote/`, `POST /v1/auth/login`), `ILLoginRepositoryImpl`
  (`Data/Repositories/`, derives the contract's `device` object from
  `UIDevice`/`Bundle` at the Data boundary — `ILLoginEntity` itself is
  unchanged), and the full `ILLoginError` failure-case set with matching
  `login.error.*` `vi.json` keys. `ILLoginUseCaseImpl` now takes
  `ILLoginRepository`/`KeychainService`/`ILUserRepository` and its `login`
  stores the session on success (same pattern as `ILOtpUseCaseImpl.verifyCode`).
  `DIContainer.makeLoginUseCase()` wired accordingly.
- Cross-feature cleanup: the refresh-token Keychain key moved from
  `ILOtpUseCaseImpl.refreshTokenKey` to
  `KeychainAuthTokenProviding.refreshTokenKey` (`Core/Networking/`) now that
  both Login and Otp write the same key — `ILOtpUseCaseImpl`'s own doc comment
  had already flagged this as the point at which the constant should move.
  `ILOtpUseCaseTests` updated to match; no behavior change for Otp.
  `APIConfig.serverBaseURL`'s `.dev` case now points at the BE team's local
  dev server (LAN IP, confirmed live 2026-09-28) instead of the mock host, with
  a matching `NSAppTransportSecurity` exception added to `Info.plist` for that
  one HTTP host — needed so the feature is actually testable on a physical
  device before a real HTTPS `.dev` host exists.
- New tests: `InnerLampTests/ILLoginRepositoryTests.swift` (DTO encoding
  including the nested `device` object, response decoding, mapper, endpoint,
  exhaustive `NetworkError` → `ILLoginError` mapping — mirrors
  `ILSignUpRepositoryTests.swift`) and `InnerLampTests/ILLoginUseCaseTests.swift`
  (mocks `ILLoginRepository`, covers session persistence and failure
  propagation — mirrors `ILOtpUseCaseTests.swift`). `ILLoginViewModelTests`
  needed no changes.
- Reason: BE confirmed the local dev backend is live and matches the
  documented contract (login + the three OTP routes), unblocking Phase 3.

## v1.1 (2026-09-27)

- `requirements.md`: removed the incorrect ⚠️ "login API contract not
  confirmed" — the contract is confirmed in `Docs/Specs/API/openapi.yaml` v3.9
  (`POST /v1/auth/login`). The submit acceptance criterion now enumerates the
  confirmed failure branches (401 INVALID_CREDENTIALS incl. the 5-fail/15-min
  lock rule, 400 validation family, 429 LOGIN_LOCKED, 413, 500). "Pending" now
  states the contract is confirmed and names the two real gaps instead: the
  entity lacks the required `device` object, and `ILLoginError` only has
  `.invalidCredentials`. The ⚠️ moved to the SMS-code item, where it actually
  belongs (the `purpose` enum lists `login` but is documented as returning
  `UNSUPPORTED_OTP_PURPOSE`).
- `design.md`: added a "Login API contract (confirmed)" section with the
  route/request/success/failure table and the two Domain gaps; the
  "Deliberately stubbed for now" section is unchanged in substance but now
  correctly says "contract confirmed, Data layer not built".
- `tasks.md`: Phase 3 heading changed from "blocked on backend contract" to
  "contract confirmed, Data layer not built"; dropped the "confirm the
  contract" task and added concrete DTO/Mapper/Endpoint/Repository/error-mapping
  tasks grounded in the confirmed contract, plus an explicit `ILLoginEntity`
  `device` gap task.
- Reason: reading `Docs/Specs/API/openapi.yaml` v3.9 while writing the
  ForgotPassword spec revealed the login contract already exists — the v1.0
  "not confirmed" claim was wrong and would have misdirected Phase 3.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Login
  feature (UI + local validation + navigation done; the login network call is
  a one-line stub with no confirmed backend contract).
- `requirements.md`: user story (returning user signs in with phone +
  password, or continues as guest) and EARS acceptance criteria for load
  state, country picker, field-error clearing, submit validation, submit
  success/failure, double-submit guard, and the four navigation paths
  (back → Onboarding, create account → SignUp, forgot → ForgotPassword, guest
  → Main). "Pending" records the stubbed `login` call and the SMS-code TODO
  with a ⚠️ Not confirmed marker on the login API contract.
- `design.md`: Layers & components table naming the actual files (Entity,
  shared `ILAuthSessionEntity`, UseCase, Repository protocol with no Data impl,
  StateModel, ViewModel, Coordinator, ViewController, `ILDividerRow`), the
  navigation flow, the submit data flow, and a "Deliberately stubbed for now"
  section explaining why the login call is a stub and what's missing.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI and logic
  plus the 9 unit tests; Phase 3 (API integration) and Phase 4 (SMS-code
  login) pending, and Phase 5's OKF concept left `[ ]` until the API lands.
- Reason: Login was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
