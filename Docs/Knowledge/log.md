# Knowledge Bundle Update Log

## 2026-09-28

- Updated `features/temple.md` after the Temple screen ("Trang chùa") was
  redesigned to match the full design handoff (`Component.TEMPLE_INFO`): the
  entity/state/viewmodel shape grew from a 3-stat mock strip to the complete
  profile (status card, facts grid, organization, architecture, amenities,
  visit rules, location & contacts), and the catalog grew from 8 to 9 temples.
  Still `status: draft` — catalog remains mock data, no temple API.

## 2026-09-27

- Full sync of the bundle against `Docs/Specs/` (the user's "read the Specs and
  update OKF" request). Added **9 feature concepts**, **3 API endpoint
  concepts**, and **2 architecture concepts**, and re-verified the 3
  pre-existing concepts against current code.
- New feature concepts (all `status: draft` except where noted), each written
  from the real code, not the spec prose: `features/otp.md` (verify/resend are
  real, only the manual real-backend test is open), `features/forgot-password.md`
  (`sendResetInstructions` is a `print("TODO")` stub; no reset contract),
  `features/onboarding.md` (`stable` — complete local flow, no backend, no
  pending work), `features/home.md` (mock content, no dashboard API),
  `features/splash.md` (post-splash route hardcoded to Onboarding),
  `features/bell.md` (memory-only; no persistence or sound picker),
  `features/library.md` (mock catalog; search/item destinations TODO),
  `features/main.md` (`stable` — complete container, no backend), and
  `features/temple.md` (mock catalog; the SRS's list/discovery scope is a draft
  with no engineering spec and is unimplemented).
- New API endpoint concepts (all `draft` — contract confirmed in
  `Docs/Specs/API/openapi.yaml` v3.9, not yet exercised against a real backend):
  `api/auth-request-otp.md`, `api/auth-verify-otp.md`,
  `api/auth-resend-otp.md`. Noted the `resend-otp` `resend_remaining` drift
  (listed in the openapi, not modeled by `ILOtpResendResponseDTO`).
- New architecture concepts (both `stable`): `architecture/networking.md` (the
  transport boundary; 401 refresh documented as deferred) and
  `architecture/logging-groups.md` (the 4 groups; 3 of 4 transports mocked by
  design).
- Re-verified `features/signup.md`: fixed one drift — the endpoint file is
  `Data/DataSources/Remote/RequestOTPEndpoint.swift` (struct
  `RequestRegistrationOTPEndpoint`), not `RequestRegistrationOTPEndpoint.swift`.
  Refreshed its OTP / endpoint related-concepts links (now written) and bumped
  `generated.at`.
- Rewrote `features/login.md` from the current code: `generated.by` is now
  `claude-code`; corrected the Forgot Password navigation (now a real
  coordinator), the guest/success destinations (now `showMain()`), added
  `ILLoginRepository` to the Architecture table, and documented the confirmed
  login contract plus the two Domain gaps (`device` object, incomplete
  `ILLoginError`).
- `domain/usecases/deviceattestation.md` re-read and found still accurate
  (three server ops still `// TODO` stubs); left untouched.
- Updated `index.md`: moved `api/` and `architecture/` out of "Planned", added
  all 17 concept rows with status reasons, and updated the planned list to
  `domain/entities/` + `design-system/`.
- Status rationale recorded here for future readers: `stable` is used only for
  features with no backend dependency and no stub (Onboarding, Main) and for
  architecture patterns that are implemented + tested with documented deferrals
  (networking, logging). Everything with a stub, mock data, or an
  unverified-against-real-backend flow stays `draft`.

## 2026-09-23 (2)

- Added `domain/usecases/deviceattestation.md` (`type: UseCase`,
  `status: draft`), documenting the DeviceAttestation background core
  service as implemented in Phases 1–3 of `Docs/Specs/DeviceAttestation/`:
  the Domain entity / repository protocol / UseCase, the
  `ILAppAttestDataSource` wrapping `DCAppAttestService` (the only file that
  imports `DeviceCheck`), the Data-layer repository, the `DIContainer`
  wiring, the App Attest environment entitlement, and the UseCase unit
  tests. This is the first concept in the `domain/` section.
- Placed it under `domain/usecases/` (not `features/`, which the spec's
  Phase 5 placeholder suggested) because the service is UI-less — no
  screen/coordinator/ViewModel — so `UseCase` is the correct `type:` per the
  bundle's taxonomy.
- Marked `draft` because the three server round-trips
  (`fetchAttestationChallenge` / `submitAttestation` /
  `fetchAssertionChallenge`) are one-line `// TODO` stubs in
  `ILDeviceAttestationRepositoryImpl` (Phase 4 is blocked on the backend
  contract), so the flow has not been exercised end-to-end. Promote to
  `stable` once the server ops are real and the attestation + assertion
  flows run against a real/staging backend.
- Moved `domain/` out of "Planned, not yet populated" in `index.md` and
  added the concept's row to the concept table.

## 2026-09-23

- Rewrote `features/signup.md` (`status: draft`) after re-reading the
  SignUp code end to end. The concept had described a feature whose
  backend call was a `print("TODO: …")` stub and whose data layer did not
  exist; both are now false. Documented the real chain
  (`ILSignUpUseCaseImpl.sendVerificationCode` → `ILSignUpRepositoryImpl` →
  `ILSignUpMapper` → `RequestRegistrationOTPEndpoint` →
  `NetworkService`), added the new `ILSignUpOTPEntity`, the DTO / mapper /
  endpoint / two test files to the Architecture table, added a
  "Submit flow and error mapping" section with the
  `NetworkError` → `ILSignUpError` table (including the 429
  `locked_until` / `retry_after_seconds` timing from `error.details`), and
  corrected the Summary: the server timing rides along to the OTP screen,
  and `phoneAlreadyRegistered` keeps the user on SignUp with an alert —
  it no longer navigates to Login, which the previous revision claimed.
- Rewrote the Pending work section: the remaining items are the manual
  real/staging verification, the unwired ToS/Privacy links (no real URLs
  provided — no placeholders invented), and the unconfirmed
  ordination-place copy/position.
- Still `draft` — the code is implemented and unit-tested, but the flow
  has not been exercised against a real/staging backend. Promote to
  `stable` once it has (same trigger as `Docs/Specs/SignUp`).
- `generated.at` refreshed; `generated.by` stays `claude-code`.
- Updated `index.md`: refreshed the `features/signup.md` status reason and
  corrected the `api/` "planned" line, which said endpoint concepts would
  be added "once real backend contracts exist" — the `request-otp`
  contract exists and is implemented, so what is actually missing is the
  concept.

## 2026-09-21 (2)

- Updated `features/signup.md` (`status: draft`) after the user confirmed
  that `phoneAlreadyRegistered` should redirect to Login. The spec
  (`Docs/Specs/SignUp/` v1.8) now matches the code, so the "Known gaps vs.
  spec" section was removed and the behavior moved into the Summary and
  "Known gaps vs. design" (the open question of whether the "phone
  already registered" message is shown after the redirect is kept there).
  Still `draft` for the same reasons as the entry below (stubbed
  `sendVerificationCode`; ordination-place copy pending the designer).

## 2026-09-21

- Updated `features/signup.md` (`status: draft`) after re-reading the
  SignUp code (`ILSignUpUseCase`, `ILSignUpEntity`, `ILSignUpStateModel`,
  `ILSignUpViewModel`, `ILSignUpViewController`, `ILEmailValidator`,
  tests). Email is now required (empty or badly formatted email blocks
  submit); the password minimum is 8 characters, up from 6; and the new
  optional ordination-place field ("Nơi xuất gia", the temple/monastery
  where a monastic was ordained) is documented in the summary,
  architecture table, field order and validation rules. Also added
  `ILEmailValidator` and the two test files to the Architecture table,
  and corrected the "stay on screen" claim: the code navigates to Login
  on `phoneAlreadyRegistered`.
- Marked `draft` because `sendVerificationCode` is still a `print("TODO")`
  stub (Phase 3 of `Docs/Specs/SignUp/tasks.md`), and because the
  ordination-place copy/position is awaiting the designer — promote to
  `stable` once the Auth API lands and the flow is verified against a
  real/staging backend.
- Flagged spec drift in `features/signup.md` ("Known gaps vs. spec"):
  the `phoneAlreadyRegistered` → Login navigation is not reflected in
  `Docs/Specs/SignUp/`. `Docs/Specs/` was not modified.
- `generated.by` changed from `copilot-cli` to `claude-code` since this
  revision was rewritten by `claude-code`. `index.md` row description
  refreshed.

## 2026-09-15 (2)

- Reviewed the Login screen (`Presentation/Scenes/Login/`, Domain
  Login entity/UseCase) and added `features/login.md` (`status: draft`).
  Documents ViewModel/Coordinator/State, navigation (incl. the
  Forgot Password push on the same nav stack), validation rules, and
  pending backend work (`login` is a stub, SMS-code login and guest
  preview are unwired TODOs). Marked `draft` for the same reason as
  SignUp — promote to `stable` once the Auth API lands and the flow is
  verified end-to-end.
- Linked `features/login.md` in `index.md`'s concept table.

## 2026-09-15

- Added `features/signup.md` (`status: draft`). Documents the SignUp
  feature (Presentation/Domain layers, navigation flow, validation
  rules) as implemented so far. Marked `draft` because backend API
  integration (`Docs/Specs/SignUp/tasks.md` Phase 3) is still pending —
  promote to `stable` once that lands and the end-to-end flow is
  verified against a real/staging backend.
- Created the bundle (`index.md`, `log.md`) as the first concept in
  `Docs/Knowledge/`.
